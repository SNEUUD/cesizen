import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final double width;
  const SideMenu({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenHeight * 0.035;
    final textSize = screenWidth * 0.015;
    final spacing = screenHeight * 0.05;
    final logoHeight = screenHeight * 0.08;

    return Container(
      width: width,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // aligner à gauche
        children: [
          SizedBox(height: screenHeight * 0.05),

          // Logo CESIzen
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Image.asset(
              'assets/images/logo.png',
              height: logoHeight,
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(height: spacing * 1.5),

          // Menu items avec icône + texte
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Row(
              children: [
                Icon(Icons.home, color: Colors.black, size: iconSize),
                SizedBox(width: 12),
                Text("Accueil", style: TextStyle(fontSize: textSize)),
              ],
            ),
          ),
          SizedBox(height: spacing),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Row(
              children: [
                Icon(Icons.settings, color: Colors.black, size: iconSize),
                SizedBox(width: 12),
                Text("Paramètres", style: TextStyle(fontSize: textSize)),
              ],
            ),
          ),
          SizedBox(height: spacing),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.black, size: iconSize),
                SizedBox(width: 12),
                Text("Profil", style: TextStyle(fontSize: textSize)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
