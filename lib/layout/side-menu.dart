import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/auth/login.dart';

class SideMenu extends StatefulWidget {
  final double width;
  const SideMenu({super.key, required this.width});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String? pseudo;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pseudo = prefs.getString('pseudo');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenHeight * 0.035;
    final textSize = screenWidth * 0.015;
    final spacing = screenHeight * 0.05;
    final logoHeight = screenHeight * 0.08;

    return Container(
      width: widget.width,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.05),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.width * 0.1),
            child: Image.asset(
              'assets/images/logo.png',
              height: logoHeight,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: spacing * 1.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.width * 0.1),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // Action pour Accueil
              },
              child: Row(
                children: [
                  Icon(Icons.home, color: Colors.black, size: iconSize),
                  SizedBox(width: 12),
                  Text("Accueil", style: TextStyle(fontSize: textSize)),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.width * 0.1),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // Action pour Paramètres
              },
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.black, size: iconSize),
                  SizedBox(width: 12),
                  Text("Paramètres", style: TextStyle(fontSize: textSize)),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.width * 0.1),
            child: pseudo == null
                ? InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.black, size: iconSize),
                        SizedBox(width: 12),
                        Text("Connexion", style: TextStyle(fontSize: textSize)),
                      ],
                    ),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.black, size: iconSize),
                        SizedBox(width: 12),
                        Text(
                          pseudo!,
                          style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
          ),
          if (pseudo != null) ...[
            SizedBox(height: spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.width * 0.1),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  setState(() {
                    pseudo = null;
                  });
                },
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black, size: iconSize),
                    SizedBox(width: 12),
                    Text(
                      "Déconnexion",
                      style: TextStyle(fontSize: textSize),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
