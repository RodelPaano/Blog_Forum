import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env first — must be before any service init
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with env-driven config
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // PKCE = more secure than implicit
      autoRefreshToken: true,
    ),
  );

  AppLogger.info('App started · env=${AppConfig.env}');

  runApp(const App());
}
