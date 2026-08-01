import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'package:blog_forum_app/core/logger.dart';
import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final IAuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _profile;
  bool _busy = false;
  String? _error;
  StreamSubscription? _sub;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isBusy => _busy;
  String? get error => _error;

  void initialize() {
    _sub = _authService.authStateChanges.listen((event) async {
      // ✅ Only handle actual sign-in/sign-out — ignore token refreshes
      final relevantEvents = {
        AuthChangeEvent.signedIn,
        AuthChangeEvent.signedOut,
        AuthChangeEvent.userUpdated,
        AuthChangeEvent.passwordRecovery,
      };

      if (!relevantEvents.contains(event.event))
        return; // ← ignore TOKEN_REFRESHED

      try {
        final session = event.session;
        if (session != null) {
          _profile = await _authService.fetchProfile(session.user.id);
          _status = AuthStatus.authenticated;
        } else {
          _profile = null;
          _status = AuthStatus.unauthenticated;
        }
        _error = null;
      } catch (e) {
        AppLogger.error('Error on auth state change', e);
        _status = AuthStatus.unauthenticated;
        _error = e.toString();
      }

      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setBusy(true);
    try {
      _profile = await _authService.signIn(email: email, password: password);
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    _setBusy(true);
    try {
      _profile = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> refreshProfile() async {
    final id = SupabaseService.currentUserId;
    if (id.isEmpty) return;
    _profile = await _authService.fetchProfile(id);
    notifyListeners();
  }

  Future<bool> updateProfile({String? fullName, File? avatarFile}) async {
    _setBusy(true);
    try {
      _profile = await _authService.updateProfile(
        userId: SupabaseService.currentUserId,
        fullName: fullName,
        avatarFile: avatarFile,
        existingAvatarUrl: _profile?.avatarUrl,
      );
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> removeAvatar() async {
    _setBusy(true);
    try {
      final current = _profile?.avatarUrl;
      if (current == null || current.isEmpty) return true;
      _profile = await _authService.removeAvatar(
        userId: SupabaseService.currentUserId,
        currentAvatarUrl: current,
      );
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
