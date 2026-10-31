import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'services/trash_spots_service.dart';
import 'screens/main_layout.dart';

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

  // Initialize background spots service
  await TrashSpotsService.instance.init();

  runApp(const StreetAIQAuthorityApp());
}

class StreetAIQAuthorityApp extends StatelessWidget {
  const StreetAIQAuthorityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Street AIQ Authority',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          primary: const Color(0xFF3B82F6),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const MainLayout(),
    );
  }
}

