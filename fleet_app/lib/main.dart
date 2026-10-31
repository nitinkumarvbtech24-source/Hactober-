import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'services/telemetry_service.dart';
import 'ui/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init: $e");
  }

  // Load saved AI server URL from preferences if available
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('garbage_ai_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      if (savedUrl.contains('pointer-staff-prodigy')) {
        await prefs.remove('garbage_ai_url');
      } else {
        GARBAGE_AI_URL = savedUrl;
      }
    }
  } catch (_) {}

  runApp(const StreetAIQFleetApp());

  // Initialize GPS telemetry asynchronously without blocking app startup
  TelemetryService().init().catchError((e) {
    debugPrint("TelemetryService async init error: $e");
  });
}

class StreetAIQFleetApp extends StatelessWidget {
  const StreetAIQFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Street AIQ Fleet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const FleetMainScreen(),
    );
  }
}

