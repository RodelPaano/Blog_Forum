import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for the Supabase instance.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static SupabaseStorageClient get storage => client.storage;

  static String get currentUserId => client.auth.currentUser?.id ?? '';

  static bool get isAuthenticated => client.auth.currentUser != null;
}
