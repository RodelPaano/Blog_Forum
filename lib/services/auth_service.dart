import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;

import '../core/exceptions.dart';
import '../core/logger.dart';
import '../core/sanitizers.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import 'storage_service.dart';

class AuthService {
  final _storage = StorageService();
  final _profileRepo = ProfileRepository();

  User? get currentUser => SupabaseService.auth.currentUser;
  Stream<AuthState> get authStateChanges =>
      SupabaseService.auth.onAuthStateChange;

  Future<UserProfile?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final cleanEmail = Sanitizers.normalizeEmail(email);
      final cleanName = Sanitizers.cleanName(fullName);

      final res = await SupabaseService.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': cleanName},
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Sign up failed. Please try again.');
      }

      // Defensive — DB trigger should also create the profile
      final existing = await _profileRepo.getById(user.id);
      if (existing == null) {
        await _profileRepo.create(
          UserProfile(
            id: user.id,
            email: cleanEmail,
            fullName: cleanName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return await _profileRepo.getById(user.id);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('signUp failed', e);
      throw AuthException(_humanizeAuthError(e));
    }
  }

  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = Sanitizers.normalizeEmail(email);
      final res = await SupabaseService.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Invalid email or password');
      }

      var profile = await _profileRepo.getById(user.id);
      if (profile == null &&
          profile?.email != cleanEmail &&
          profile?.fullName != 'User') {
        profile = await _profileRepo.create(
          UserProfile(
            id: user.id,
            email: cleanEmail,
            fullName: 'User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return profile;
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('signIn failed', e);
      throw AuthException(_humanizeAuthError(e));
    }
  }

  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
  }

  Future<UserProfile?> fetchProfile(String userId) async {
    final existing = await _profileRepo.getById(userId);
    if (existing != null) return existing;

    final user = SupabaseService.auth.currentUser;
    if (user == null || user.id != userId) return null;

    final fallback = UserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: (user.userMetadata?['full_name'] as String?) ?? 'User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _profileRepo.create(fallback);
  }

  /// Updates the authenticated user's profile. Handles avatar upload
  /// + safe deletion of the old avatar.
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    File? avatarFile,
    String? existingAvatarUrl,
  }) async {
    try {
      String? newAvatarUrl = existingAvatarUrl;

      if (avatarFile != null) {
        newAvatarUrl = await _storage.uploadImage(
          XFile(avatarFile.path),
          folder: 'avatars',
        );
        // Delete old avatar AFTER successful upload
        if (existingAvatarUrl != null &&
            existingAvatarUrl.isNotEmpty &&
            existingAvatarUrl != newAvatarUrl) {
          await _storage.deleteImageByUrl(existingAvatarUrl);
        }
      }

      final cleanName = fullName != null
          ? Sanitizers.cleanName(fullName)
          : null;

      return await _profileRepo.updateProfile(
        userId: userId,
        fullName: cleanName,
        avatarUrl: newAvatarUrl,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      AppLogger.error('updateProfile failed', e);
      throw DatabaseException('Profile update failed');
    }
  }

  Future<UserProfile> removeAvatar({
    required String userId,
    required String currentAvatarUrl,
  }) async {
    await _storage.deleteImageByUrl(currentAvatarUrl);
    return _profileRepo.updateProfile(userId: userId, clearAvatar: true);
  }

  String _humanizeAuthError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (s.contains('user already registered')) {
      return 'An account with this email already exists';
    }
    if (s.contains('email not confirmed')) {
      return 'Please confirm your email first';
    }
    if (s.contains('password should be')) {
      return 'Password is too weak';
    }
    if (s.contains('rate limit') || s.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (s.contains('network') || s.contains('socket')) {
      return 'Network error. Check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }
}
