import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:uuid/uuid.dart';

// dart:io for mobile only
import 'dart:io' as io;

import '../core/config.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../utils/image_utils.dart';
import '../utils/url_utils.dart';

class StorageService {
  static const _uuid = Uuid();

  /// Uploads an image with full validation (size, MIME, magic bytes,
  /// extension allowlist). Returns the public URL.
  /// Accepts XFile — works on Web and Mobile.
  Future<String> uploadImage(XFile file, {required String folder}) async {
    // Read bytes once — works on both web and mobile
    final bytes = await file.readAsBytes();

    // Validate using XFile (updated ImageUtils)
    if (!await ImageUtils.isValidImage(file)) {
      throw const StorageException(
        'Invalid image. Only JPEG, PNG, WEBP, GIF allowed.',
      );
    }

    // Size check using bytes (no dart:io needed)
    if (bytes.length > AppConfig.maxImageBytes) {
      throw const StorageException('Image exceeds 5 MB limit.');
    }

    // Extension check using file.name (not file.path)
    if (!ImageUtils.isAllowedExtension(file.name)) {
      throw const StorageException('File extension not allowed.');
    }

    // MIME — use headerBytes for accuracy on both platforms
    final nameForMime =
        (file.name.contains('.') && !file.name.startsWith('blob:'))
        ? file.name
        : '';
    final mime =
        lookupMimeType(nameForMime, headerBytes: bytes) ?? 'image/jpeg';

    var ext = p.extension(file.name).toLowerCase();
    if (ext.isEmpty ||
        ext == '.tmp' ||
        file.name.startsWith('blob:') ||
        !AppConfig.allowedImageExtensions.contains(ext)) {
      switch (mime) {
        case 'image/png':
          ext = '.png';
          break;
        case 'image/webp':
          ext = '.webp';
          break;
        case 'image/gif':
          ext = '.gif';
          break;
        default:
          ext = '.jpg';
      }
    }
    final safeFolder = _sanitizeFolder(folder);
    final fileName = '$safeFolder/${_uuid.v4()}$ext';

    try {
      if (kIsWeb) {
        // WEB — must use uploadBinary with bytes
        await SupabaseService.storage
            .from(AppConfig.storageBucket)
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: mime, upsert: false),
            );
      } else {
        // MOBILE — can use upload with File
        final ioFile = io.File(file.path);
        await SupabaseService.storage
            .from(AppConfig.storageBucket)
            .upload(
              fileName,
              ioFile,
              fileOptions: FileOptions(contentType: mime, upsert: false),
            );
      }

      final url = SupabaseService.storage
          .from(AppConfig.storageBucket)
          .getPublicUrl(fileName);

      AppLogger.info('Uploaded → $safeFolder');
      return url;
    } on StorageException catch (e) {
      throw StorageException('Upload failed: ${e.message}');
    } catch (e) {
      AppLogger.error('Storage upload failed', e);
      throw StorageException('Upload failed. Please try again.');
    }
  }

  /// Deletes an image given its public URL. Best-effort, swallows errors
  /// to avoid breaking the calling flow.
  Future<void> deleteImageByUrl(String publicUrl) async {
    try {
      final key = UrlUtils.extractStorageKey(
        publicUrl,
        bucket: AppConfig.storageBucket,
      );
      if (key == null || key.isEmpty) return;
      if (key.contains('..')) {
        AppLogger.warn('Refusing to delete key with ..');
        return;
      }
      await SupabaseService.storage.from(AppConfig.storageBucket).remove([key]);
    } catch (e) {
      AppLogger.warn('Delete failed for URL: $e');
    }
  }

  Future<void> deleteImages(List<String> publicUrls) async {
    final keys = <String>[];
    for (final url in publicUrls) {
      final k = UrlUtils.extractStorageKey(
        url,
        bucket: AppConfig.storageBucket,
      );
      if (k != null && k.isNotEmpty && !k.contains('..')) {
        keys.add(k);
      }
    }
    if (keys.isEmpty) return;
    try {
      await SupabaseService.storage.from(AppConfig.storageBucket).remove(keys);
    } catch (e) {
      AppLogger.warn('Bulk delete failed: $e');
    }
  }

  String _sanitizeFolder(String folder) {
    final cleaned = folder.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    return cleaned.isEmpty ? 'misc' : cleaned;
  }
}
