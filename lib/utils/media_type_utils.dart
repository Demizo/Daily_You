// Behavior based on DenserMeerkat/June (GPL-3.0)

class MediaTypeUtils {
  static const videoExtensions = {'.mp4', '.mov', '.webm', '.mkv', '.avi'};

  static bool isVideo(String path) {
    final lower = path.toLowerCase();
    return videoExtensions.any((ext) => lower.endsWith(ext));
  }
}
