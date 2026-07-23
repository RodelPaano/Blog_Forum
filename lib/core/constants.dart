/// Static, non-secret constants used across the app.
class AppConstants {
  AppConstants._();

  // Storage folder names
  static const String folderAvatars = 'avatars';
  static const String folderPosts = 'posts';
  static const String folderComments = 'comments';

  // UI
  static const double defaultPadding = 16.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  // Pagination scroll threshold
  static const double loadMoreThreshold = 300.0;

  // Animation
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 350);
}
