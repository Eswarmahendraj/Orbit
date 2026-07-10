import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Extracts a JPEG thumbnail from [videoPath] and saves it to the
/// system temp directory. Returns the thumbnail file path, or null on error.
Future<String?> extractVideoThumbnail(String videoPath) async {
  try {
    final dir = await getTemporaryDirectory();
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: dir.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 600,
      quality: 85,
    );
    return thumbPath;
  } catch (_) {
    return null;
  }
}
