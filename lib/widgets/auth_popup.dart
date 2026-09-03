import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum AuthPopupMode { unlock, enterPassword, setPassword, changePassword }

class AuthPopup extends StatefulWidget {
  final AuthPopupMode mode;
  final String title;
  final String? description;
  final bool showBiometrics;
  final bool dismissable;
  final PasswordStore store;
  final void Function(String password)? onSuccess;

  const AuthPopup({
    super.key,
    required this.mode,
    required this.title,
    this.description,
    required this.showBiometrics,
    required this.dismissable,
    this.store = const AppPasswordStore(),
    this.onSuccess,
  });

  @override
  State<AuthPopup> createState() => _AuthPopupState();
}

class _AuthPopupState extends State<AuthPopup> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _error;
  bool _showPassword = false;
  bool _biometricsPrompted = false;
  bool _isPin = false;
  bool _passwordFocusRequested = false;
  Animation<double>? _routeAnimation;

  bool get _asksForNewPassword =>
      widget.mode == AuthPopupMode.setPassword ||
      widget.mode == AuthPopupMode.changePassword;

  @override
  void initState() {
    super.initState();
    if (widget.mode == AuthPopupMode.unlock) {
      _isPin = widget.store.isPin;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Request keyboard focus after dialog animation completes
    if (!_asksForNewPassword && !widget.showBiometrics) {
      final animation = ModalRoute.of(context)?.animation;
      if (animation != _routeAnimation) {
        _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
        _routeAnimation = animation;
        _routeAnimation?.addStatusListener(_handleRouteAnimationStatus);
        if (_routeAnimation == null || _routeAnimation!.isCompleted) {
          _requestPasswordFocus();
        }
      }
    }
  }

  void _handleRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _requestPasswordFocus();
    }
  }

  void _requestPasswordFocus() {
    if (_passwordFocusRequested) return;
    _passwordFocusRequested = true;
    _passwordFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    _oldController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<bool> authenticateWithBiometrics() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    if (!canCheck) return false;
    if (!mounted) return false;

    bool success = false;
    try {
      final bool didAuthenticate = await auth.authenticate(
        persistAcrossBackgrounding: false,
        biometricOnly: true,
        localizedReason: AppLocalizations.of(context)!.unlockAppPrompt,
      );
      success = didAuthenticate;
    } on PlatformException {
      success = false;
    }
    return success;
  }

  void _succeed(String password) {
    if (!mounted) return;
    widget.onSuccess?.call(password);
    Navigator.of(context).pop();
  }

  Future<void> _handleSubmit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      switch (widget.mode) {
        case AuthPopupMode.unlock:
          if (await widget.store.validate(_passwordController.text)) {
            _succeed(_passwordController.text);
          } else {
            setState(
              () => _error = AppLocalizations.of(context)!
                  .settingsSecurityIncorrectPassword,
            );
          }
          break;

        case AuthPopupMode.enterPassword:
          _succeed(_passwordController.text);
          break;

        case AuthPopupMode.setPassword:
        case AuthPopupMode.changePassword:
          if (widget.mode == AuthPopupMode.changePassword &&
              !await widget.store.validate(_oldController.text)) {
            setState(
              () => _error = AppLocalizations.of(context)!
                  .settingsSecurityIncorrectPassword,
            );
            break;
          }
          if (_passwordController.text != _confirmController.text) {
            setState(
              () => _error = AppLocalizations.of(context)!
                  .settingsSecurityPasswordsDoNotMatch,
            );
            break;
          }
          await widget.store.save(_passwordController.text);
          _succeed(_passwordController.text);
          break;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleBiometric() async {
    if (await authenticateWithBiometrics()) {
      _succeed('');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showBiometrics && !_biometricsPrompted) {
      _biometricsPrompted = true;
      _handleBiometric();
    }
    return PopScope(
      canPop: widget.dismissable,
      child: AlertDialog(
        title: Column(
          children: [
            Center(
              child: Icon(
                Icons.lock_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 32,
              ),
            ),
            SizedBox(height: 4),
            Text(widget.title),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.description != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(widget.description!),
                ),
              if (widget.mode == AuthPopupMode.changePassword) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _oldController,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      labelText: AppLocalizations.of(context)!
                          .settingsSecurityOldPassword,
                    ),
                    validator: (v) => v!.isEmpty
                        ? AppLocalizations.of(context)!.requiredPrompt
                        : null,
                  ),
                ),
                Divider(),
              ],
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: !_showPassword,
                  autocorrect: false,
                  keyboardType: widget.mode == AuthPopupMode.unlock && _isPin
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    labelText:
                        AppLocalizations.of(context)!.settingsSecurityPassword,
                  ),
                  validator: (v) => v!.isEmpty
                      ? AppLocalizations.of(context)!.requiredPrompt
                      : null,
                ),
              ),
              if (_asksForNewPassword)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _confirmController,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      labelText: AppLocalizations.of(context)!
                          .settingsSecurityConfirmPassword,
                    ),
                    validator: (v) => v!.isEmpty
                        ? AppLocalizations.of(context)!.requiredPrompt
                        : null,
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (widget.mode == AuthPopupMode.unlock && widget.showBiometrics)
                IconButton(
                  onPressed: _handleBiometric,
                  icon: const Icon(Icons.fingerprint),
                  iconSize: 32,
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        !_showPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : IconButton.filled(
                            onPressed: _handleSubmit,
                            icon: Icon(Icons.check_rounded),
                            iconSize: 28,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
