import 'config.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    if (value.length > 254) return 'Email too long';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (value.length > 128) return 'Password too long';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    if (value.length > AppConfig.maxNameLength) return 'Name is too long';
    return null;
  }

  static String? postTitle(String? value) {
    if (value == null || value.trim().isEmpty) return 'Title is required';
    if (value.length > AppConfig.maxTitleLength) return 'Title too long';
    return null;
  }

  static String? postContent(String? value) {
    if (value == null || value.trim().isEmpty) return 'Content is required';
    if (value.length > AppConfig.maxContentLength) return 'Content too long';
    return null;
  }

  static String? comment(String? value) {
    if (value == null || value.trim().isEmpty) return 'Comment cannot be empty';
    if (value.length > AppConfig.maxCommentLength) return 'Comment too long';
    return null;
  }
}
