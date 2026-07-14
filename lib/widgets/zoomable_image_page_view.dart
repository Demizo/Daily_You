import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A [PageView] of zoomable images.
///
/// Uses [_ArenaAwarePanRecognizer] to proactively claim single-finger drags
/// once an image is zoomed in, rather than racing the page view's own drag
/// recognizer for them.
class ZoomableImagePageView extends StatefulWidget {
  const ZoomableImagePageView({
    super.key,
    required this.imageProviders,
    required this.controller,
    this.onPageChanged,
    this.errorBuilder,
    this.minScale = 1.0,
    this.maxScale = 10.0,
    this.doubleTapScale = 2.0,
  });

  final List<ImageProvider> imageProviders;
  final PageController controller;
  final ValueChanged<int>? onPageChanged;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final double minScale;
  final double maxScale;
  final double doubleTapScale;

  @override
  State<ZoomableImagePageView> createState() => _ZoomableImagePageViewState();
}

enum _PanVerdict { release, compete, claim }

class _ZoomableImagePageViewState extends State<ZoomableImagePageView>
    with SingleTickerProviderStateMixin {
  late int _currentIndex = widget.controller.initialPage;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _lastCumulativeScale = 1.0;
  Size _viewportSize = Size.zero;
  Size? _imageSize;
  Offset? _doubleTapLocalPosition;
  AxisDirection? _lastGestureDirection;
  _PanVerdict? _lastGestureVerdict;

  /// Drives the page view's own scroll position when a claimed drag turns
  /// out to be heading toward an edge with no room left to pan.
  Drag? _pageDrag;

  /// [FrictionSimulation]'s exponential-decay for panning
  static const double _panFrictionCoefficient = 0.0000135;
  late final AnimationController _panFlingController =
      AnimationController(vsync: this);
  Animation<Offset>? _panFlingAnimation;

  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageSize(_currentIndex);
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _pageDrag?.cancel();
    _panFlingController.dispose();
    super.dispose();
  }

  void _resolveImageSize(int index) {
    final provider = widget.imageProviders[index];
    final newStream = provider.resolve(createLocalImageConfiguration(context));
    if (newStream.key == _imageStream?.key) return;
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = newStream;
    _imageStreamListener = ImageStreamListener((info, synchronous) {
      if (!mounted) return;
      setState(() {
        _imageSize =
            Size(info.image.width.toDouble(), info.image.height.toDouble());
      });
    });
    _imageStream!.addListener(_imageStreamListener!);
  }

  void _handlePageChanged(int index) {
    _stopPanFling();
    setState(() {
      _currentIndex = index;
      _scale = 1.0;
      _offset = Offset.zero;
      _imageSize = null;
    });
    _resolveImageSize(index);
    widget.onPageChanged?.call(index);
  }

  /// Image size fitted into the viewport, before [_scale] is applied
  Size? _fittedImageSize() {
    final imageSize = _imageSize;
    if (imageSize == null || _viewportSize.isEmpty) return null;
    return applyBoxFit(BoxFit.contain, imageSize, _viewportSize).destination;
  }

  /// The current page's rendered image bounds, in local coordinates
  Rect? _contentRect() {
    final fittedSize = _fittedImageSize();
    if (fittedSize == null) return null;
    final contentSize = fittedSize * _scale;
    final center = _viewportSize.center(Offset.zero) + _offset;
    return Rect.fromCenter(
      center: center,
      width: contentSize.width,
      height: contentSize.height,
    );
  }

  static const double _edgeEpsilon = 0.5;

  /// Whether a pan in [direction] should release to the page view, compete
  /// normally, or be claimed for pan/zoom.
  _PanVerdict _verdictAt(AxisDirection direction) {
    final verdict = _computeVerdict(direction);
    _lastGestureDirection = direction;
    _lastGestureVerdict = verdict;
    return verdict;
  }

  _PanVerdict _computeVerdict(AxisDirection direction) {
    final rect = _contentRect();
    if (rect == null) return _PanVerdict.compete;

    final isHorizontal =
        direction == AxisDirection.left || direction == AxisDirection.right;
    final contentExtent = isHorizontal ? rect.width : rect.height;
    final viewportExtent =
        isHorizontal ? _viewportSize.width : _viewportSize.height;
    if (contentExtent <= viewportExtent + _edgeEpsilon) {
      return _PanVerdict.release;
    }

    final hasRoomBeyondEdge = switch (direction) {
      AxisDirection.left => rect.right > viewportExtent + _edgeEpsilon,
      AxisDirection.right => rect.left < -_edgeEpsilon,
      AxisDirection.up => rect.bottom > viewportExtent + _edgeEpsilon,
      AxisDirection.down => rect.top < -_edgeEpsilon,
    };
    return hasRoomBeyondEdge ? _PanVerdict.claim : _PanVerdict.release;
  }

  bool _isZoomed() => _scale > 1.0 + 0.001;

  Offset _clampOffset(Offset offset, double scale) {
    final fittedSize = _fittedImageSize();
    if (fittedSize == null) return Offset.zero;
    final contentSize = fittedSize * scale;
    final maxDx = math.max(0.0, (contentSize.width - _viewportSize.width) / 2);
    final maxDy =
        math.max(0.0, (contentSize.height - _viewportSize.height) / 2);
    return Offset(
      offset.dx.clamp(-maxDx, maxDx),
      offset.dy.clamp(-maxDy, maxDy),
    );
  }

  /// Applies [newScale] while keeping the content point under [focalLocal]
  void _applyFocalScale(
      Offset focalLocal, Offset? focalLocalDelta, double newScale) {
    final viewportCenter = _viewportSize.center(Offset.zero);
    final oldFocalLocal = focalLocal - (focalLocalDelta ?? Offset.zero);
    final anchor = (oldFocalLocal - viewportCenter - _offset) / _scale;
    final desiredOffset = focalLocal - viewportCenter - anchor * newScale;
    setState(() {
      _scale = newScale;
      _offset = _clampOffset(desiredOffset, newScale);
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastCumulativeScale = 1.0;
    _lastGestureDirection = null;
    _lastGestureVerdict = null;
    _stopPanFling();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_lastGestureVerdict == _PanVerdict.release &&
        (_lastGestureDirection == AxisDirection.left ||
            _lastGestureDirection == AxisDirection.right)) {
      _updatePageDrag(details);
      return;
    }
    final incrementalFactor = details.scale / _lastCumulativeScale;
    _lastCumulativeScale = details.scale;
    final newScale =
        (_scale * incrementalFactor).clamp(widget.minScale, widget.maxScale);
    _applyFocalScale(
        details.localFocalPoint, details.focalPointDelta, newScale);
  }

  /// Manually drives the page view's [ScrollPosition] via [Drag]
  void _updatePageDrag(ScaleUpdateDetails details) {
    final position = widget.controller.position;
    final dx = details.focalPointDelta.dx;
    _pageDrag ??= position.drag(
      DragStartDetails(
        sourceTimeStamp: details.sourceTimeStamp,
        globalPosition: details.focalPoint,
        localPosition: details.localFocalPoint,
      ),
      () => _pageDrag = null,
    );
    _pageDrag?.update(DragUpdateDetails(
      sourceTimeStamp: details.sourceTimeStamp,
      globalPosition: details.focalPoint,
      localPosition: details.localFocalPoint,
      delta: Offset(dx, 0),
      primaryDelta: dx,
    ));
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    final verdict = _lastGestureVerdict;
    _lastGestureDirection = null;
    _lastGestureVerdict = null;

    if (_pageDrag != null) {
      final dx = details.velocity.pixelsPerSecond.dx;
      _pageDrag!.end(DragEndDetails(
        velocity: Velocity(pixelsPerSecond: Offset(dx, 0)),
        primaryVelocity: dx,
      ));
      _pageDrag = null;
      return;
    }

    if (verdict != null &&
        details.velocity.pixelsPerSecond.distance >= kMinFlingVelocity) {
      _startPanFling(details.velocity.pixelsPerSecond);
    }
  }

  void _stopPanFling() {
    _panFlingController.stop();
    _panFlingAnimation?.removeListener(_handlePanFlingTick);
    _panFlingAnimation = null;
  }

  /// Lets a fast pan keep gliding briefly after release
  void _startPanFling(Offset velocity) {
    final frictionX =
        FrictionSimulation(_panFrictionCoefficient, _offset.dx, velocity.dx);
    final frictionY =
        FrictionSimulation(_panFrictionCoefficient, _offset.dy, velocity.dy);
    final finalTime =
        _flingFinalTime(velocity.distance, _panFrictionCoefficient);

    _panFlingAnimation = Tween<Offset>(
      begin: _offset,
      end: Offset(frictionX.finalX, frictionY.finalX),
    ).animate(
        CurvedAnimation(parent: _panFlingController, curve: Curves.decelerate));
    _panFlingController.duration =
        Duration(milliseconds: (finalTime * 1000).round().clamp(1, 2000));
    _panFlingAnimation!.addListener(_handlePanFlingTick);
    _panFlingController
      ..reset()
      ..forward();
  }

  void _handlePanFlingTick() {
    final animation = _panFlingAnimation;
    if (animation == null) return;
    setState(() {
      _offset = _clampOffset(animation.value, _scale);
    });
  }

  /// Time until friction-decelerated motion drops below
  /// [effectivelyMotionless] px/s
  static double _flingFinalTime(double velocity, double drag,
      {double effectivelyMotionless = 10}) {
    return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
  }

  void _handleDoubleTap() {
    final position = _doubleTapLocalPosition;
    if (position == null) return;
    _stopPanFling();
    final targetScale = _scale > widget.minScale + 0.01
        ? widget.minScale
        : widget.doubleTapScale;
    _applyFocalScale(position, null, targetScale);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _stopPanFling();
      final zoomFactor =
          math.exp(-event.scrollDelta.dy / kDefaultMouseScrollToScaleFactor);
      final newScale =
          (_scale * zoomFactor).clamp(widget.minScale, widget.maxScale);
      _applyFocalScale(event.localPosition, null, newScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _viewportSize = constraints.biggest;
      return Listener(
        onPointerSignal: _handlePointerSignal,
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: <Type, GestureRecognizerFactory>{
            _ArenaAwarePanRecognizer:
                GestureRecognizerFactoryWithHandlers<_ArenaAwarePanRecognizer>(
              () => _ArenaAwarePanRecognizer(
                  isZoomed: _isZoomed, verdictAt: _verdictAt),
              (recognizer) {
                recognizer
                  ..onStart = _handleScaleStart
                  ..onUpdate = _handleScaleUpdate
                  ..onEnd = _handleScaleEnd;
              },
            ),
            DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                DoubleTapGestureRecognizer>(
              DoubleTapGestureRecognizer.new,
              (recognizer) {
                recognizer
                  ..onDoubleTapDown = (details) {
                    _doubleTapLocalPosition = details.localPosition;
                  }
                  ..onDoubleTap = _handleDoubleTap;
              },
            ),
          },
          child: PageView.builder(
            controller: widget.controller,
            physics: const FastPageViewScrollPhysics(),
            itemCount: widget.imageProviders.length,
            onPageChanged: _handlePageChanged,
            itemBuilder: _buildPage,
          ),
        ),
      );
    });
  }

  Widget _buildPage(BuildContext context, int index) {
    final image = Image(
      image: widget.imageProviders[index],
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorBuilder?.call(context, error) ??
            const Center(
              child: Icon(Icons.image_search_rounded, size: 36),
            );
      },
    );

    if (index != _currentIndex) return image;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
        ..scaleByDouble(_scale, _scale, _scale, 1),
      child: image,
    );
  }
}

/// Proactively claims a single-finger drag once [isZoomed], so it
/// wins the gesture arena. A second pointer is always claimed immediately.
/// [verdictAt] is consulted separately to decide how the claimed gesture should behave.
///
/// Keeps its own `_origins` map since [ScaleGestureRecognizer]'s pointer
/// tracking is private to its defining library.
class _ArenaAwarePanRecognizer extends ScaleGestureRecognizer {
  _ArenaAwarePanRecognizer({required this.isZoomed, required this.verdictAt});

  final bool Function() isZoomed;
  final _PanVerdict Function(AxisDirection direction) verdictAt;

  final Map<int, Offset> _origins = <int, Offset>{};
  bool _directionResolved = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (_origins.isEmpty) {
      _directionResolved = false;
    }
    _origins[event.pointer] = event.position;
    if (_origins.length == 2) {
      _directionResolved = true;
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent &&
        _origins.length == 1 &&
        !_directionResolved &&
        _origins.containsKey(event.pointer)) {
      final movement = event.position - _origins[event.pointer]!;
      final claimThreshold = computeHitSlop(event.kind, gestureSettings) / 6;
      if (movement.distance > claimThreshold) {
        _directionResolved = true;
        if (isZoomed()) {
          resolve(GestureDisposition.accepted);
        }
        final direction = movement.dx.abs() >= movement.dy.abs()
            ? (movement.dx > 0 ? AxisDirection.right : AxisDirection.left)
            : (movement.dy > 0 ? AxisDirection.down : AxisDirection.up);
        verdictAt(direction);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _origins.remove(event.pointer);
    }
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _origins.remove(pointer);
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _origins.clear();
    _directionResolved = false;
    super.didStopTrackingLastPointer(pointer);
  }
}

/// Lazily loads image bytes for [Image] via [ImageStorage]
class EntryImageProvider extends ImageProvider<EntryImageProvider> {
  const EntryImageProvider(this.imagePath);

  final String imagePath;

  @override
  Future<EntryImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<EntryImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      EntryImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: imagePath,
    );
  }

  Future<ui.Codec> _loadAsync(
      EntryImageProvider key, ImageDecoderCallback decode) async {
    final bytes = await ImageStorage.instance.getBytes(key.imagePath);
    if (bytes == null) {
      throw StateError('Image not found: ${key.imagePath}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is EntryImageProvider && other.imagePath == imagePath;
  }

  @override
  int get hashCode => imagePath.hashCode;
}
