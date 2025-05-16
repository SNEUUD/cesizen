import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final double width;
  const SideMenu({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // Logo CESIzen
         Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Image.asset('assets/images/logo.png', height: 60),
          ),

          // Icônes du menu
          const Icon(Icons.home, color: Colors.white),
          const SizedBox(height: 20),
          const Icon(Icons.settings, color: Colors.white),
          const SizedBox(height: 20),
          const Icon(Icons.person, color: Colors.white),
        ],
      ),
    );
  }
}
