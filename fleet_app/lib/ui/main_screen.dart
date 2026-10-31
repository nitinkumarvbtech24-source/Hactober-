import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'map_screen.dart';
import 'camera_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';

class FleetMainScreen extends StatefulWidget {
  const FleetMainScreen({super.key});

  @override
  State<FleetMainScreen> createState() => _FleetMainScreenState();
}

class _FleetMainScreenState extends State<FleetMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FleetMapScreen(),
    FleetCameraScreen(),
    TasksScreen(),
    FleetSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.map), label: 'Live Map'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.camera), label: 'AI Camera'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.checkSquare), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

