import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'layout/side-menu.dart';
import 'pages/ressources.dart';
import 'pages/rapports.dart';

void main() {
  runApp(const MainApp());
}

class Ressource {
  final int id;
  final String titre;
  final String message;
  final DateTime date;
  final Uint8List? image;

  Ressource({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    this.image,
  });

  factory Ressource.fromJson(Map<String, dynamic> json) {
    return Ressource(
      id: json['idRessource'],
      titre: json['titreRessource'],
      message: json['messageRessource'],
      date: DateTime.parse(json['dateRessource']),
      image:
          json['imageRessource'] != null
              ? base64Decode(json['imageRessource'])
              : null,
    );
  }
}

Future<List<Ressource>> fetchRessources() async {
  final response = await http.get(Uri.parse('http://0.0.0.0:3050/ressources'));

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Ressource.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des ressources');
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String currentPage = 'ressources';
  String? userId;
  int? userRole; // Ajoute cette variable

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('id');
      userRole = prefs.getInt(
        'role',
      ); // Stocke le rôle dans les prefs lors de la connexion
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          final menuWidth = isMobile ? 0.0 : constraints.maxWidth / 4;

          return Scaffold(
            backgroundColor: Colors.grey[200],
            body: Row(
              children: [
                if (!isMobile)
                  SideMenu(
                    width: menuWidth,
                    onAccueil: () => setState(() => currentPage = 'ressources'),
                    onTrackers: () => setState(() => currentPage = 'rapports'),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 4.0 : 16.0),
                    child:
                        currentPage == 'ressources'
                            ? RessourcesPage(
                              isMobile: isMobile,
                              userRole: userRole ?? 1, // Passe le rôle ici
                            )
                            : RapportsPage(
                              isMobile: isMobile,
                              userId: userId ?? '',
                            ),
                  ),
                ),
              ],
            ),
            drawer:
                isMobile
                    ? Drawer(
                      child: SideMenu(
                        width: constraints.maxWidth * 0.7,
                        onAccueil: () {
                          setState(() => currentPage = 'ressources');
                          Navigator.pop(context);
                        },
                        onTrackers: () {
                          setState(() => currentPage = 'rapports');
                          Navigator.pop(context);
                        },
                      ),
                    )
                    : null,
          );
        },
      ),
    );
  }
}
