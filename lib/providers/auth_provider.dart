import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

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

  get errorMessage => null;

  void initialize() {
    _sub = _service.authStateChanges.listen((event) async {
      final session = event.session;
      if (session != null) {
        _profile = await _service.fetchProfile(session.user.id);
        _status = AuthStatus.authenticated;
      } else {
        _profile = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setBusy(true);
    try {
      _profile = await _service.signIn(email: email, password: password);
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
      _profile = await _service.signUp(
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
    await _service.signOut();
  }

  Future<void> refreshProfile() async {
    final id = SupabaseService.currentUserId;
    if (id.isEmpty) return;
    _profile = await _service.fetchProfile(id);
    notifyListeners();
  }

  Future<bool> updateProfile({String? fullName, File? avatarFile}) async {
    _setBusy(true);
    try {
      _profile = await _service.updateProfile(
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
      _profile = await _service.removeAvatar(
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
