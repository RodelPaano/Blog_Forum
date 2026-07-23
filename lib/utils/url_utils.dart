/// URL safety & parsing utilities.
class UrlUtils {
  UrlUtils._();

  /// Extracts the storage object key from a public Supabase storage URL.
  /// Example: https://xxx.supabase.co/storage/v1/object/public/blog-media/posts/abc.jpg
  ///       → posts/abc.jpg
  /// Returns null if the URL doesn't match the expected pattern or bucket.
  static String? extractStorageKey(String publicUrl, {required String bucket}) {
    try {
      final uri = Uri.parse(publicUrl);
      if (uri.scheme != 'https' && uri.scheme != 'http') return null;
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1 || bucketIndex == segments.length - 1) {
        return null;
      }
      final key = segments.sublist(bucketIndex + 1).join('/');
      if (key.contains('..') || key.startsWith('/')) return null;
      return key;
    } catch (_) {
      return null;
    }
  }

  static bool isSafeDisplayUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme) return false;
      if (uri.scheme != 'https' && uri.scheme != 'http') return false;
      if (uri.host.isEmpty) return false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
