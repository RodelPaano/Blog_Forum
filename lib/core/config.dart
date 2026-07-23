import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized, type-safe access to environment variables.
/// NEVER hardcode secrets — read from .env at boot.
class AppConfig {
  AppConfig._();

  // ---- Supabase ----
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      (throw StateError('SUPABASE_URL missing in .env'));

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      (throw StateError('SUPABASE_ANON_KEY missing in .env'));

  static String get storageBucket =>
      dotenv.env['SUPABASE_STORAGE_BUCKET'] ?? 'blog-media';

  // ---- App ----
  static String get env => dotenv.env['APP_ENV'] ?? 'development';

  // ---- Limits ----
  static const int pageSize = 10;
  static const int maxImagesPerPost = 8;
  static const int maxImagesPerComment = 4;
  static const int maxImageBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxImageDimension = 4096; // anti-decompression-bomb
  static const int minImageDimension = 32;
  static const int maxTitleLength = 200;
  static const int maxContentLength = 10000;
  static const int maxCommentLength = 2000;
  static const int maxNameLength = 100;
  static const List<String> allowedImageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  ];
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
  ];
}
