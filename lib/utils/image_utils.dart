import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../core/config.dart';

/// Image validation utilities — multi-layer defense.
/// Compatible with Flutter Web and Mobile.
class ImageUtils {
  ImageUtils._();

  /// Magic bytes (file signatures) for allowed image types.
  static const _magicBytes = <List<int>>[
    [0xFF, 0xD8, 0xFF], // JPEG
    [0x89, 0x50, 0x4E, 0x47], // PNG
    [0x47, 0x49, 0x46, 0x38], // GIF
    [0x52, 0x49, 0x46, 0x46], // WEBP (RIFF — needs further check)
  ];

  static bool isAllowedExtension(String path) {
    if (path.startsWith('blob:') || !path.contains('.')) return true;
    final ext = p.extension(path).toLowerCase();
    if (ext.isEmpty || ext == '.tmp') return true;
    return AppConfig.allowedImageExtensions.contains(ext);
  }

  /// ✅ Main validation — accepts XFile (works on web + mobile)
  static Future<bool> isValidImage(XFile? file) async {
    if (file == null) return false;

    // ✅ Read bytes once — works on BOTH web and mobile
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      debugPrint('Failed to read file bytes: $e');
      return false;
    }

    // ✅ Size checks
    if (bytes.isEmpty) return false;
    if (bytes.length > AppConfig.maxImageBytes) return false;

    // ✅ Magic bytes check — ground truth signature check first
    if (!_hasValidMagicBytes(bytes)) return false;

    // ✅ Extension check if a normal filename extension exists
    if (!isAllowedExtension(file.name)) return false;

    // ✅ MIME type check — pass name only if valid extension, else headerBytes lookup
    final nameForMime =
        (file.name.contains('.') && !file.name.startsWith('blob:'))
        ? file.name
        : '';
    final mime = lookupMimeType(nameForMime, headerBytes: bytes);
    if (mime != null && !AppConfig.allowedImageMimeTypes.contains(mime)) {
      return false;
    }

    return true;
  }

  /// ✅ Now synchronous — bytes already loaded, no more file I/O
  static bool _hasValidMagicBytes(Uint8List bytes) {
    try {
      if (bytes.length < 12) return false;
      if (!_startsWithAny(bytes, _magicBytes)) return false;

      // WEBP: "RIFF....WEBP" — verify WEBP marker at offset 8
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50;
      }

      return true;
    } catch (e) {
      debugPrint('Magic byte check failed: $e');
      return false;
    }
  }

  static bool _startsWithAny(Uint8List bytes, List<List<int>> sigs) {
    for (final sig in sigs) {
      if (bytes.length < sig.length) continue;
      bool match = true;
      for (var i = 0; i < sig.length; i++) {
        if (bytes[i] != sig[i]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  static String humanFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
