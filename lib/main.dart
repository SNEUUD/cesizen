import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'layout/side-menu.dart';

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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
                  SideMenu(width: menuWidth),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 4.0 : 16.0),
                    child: RessourceList(isMobile: isMobile),
                  ),
                ),
              ],
            ),
            drawer: isMobile
                ? Drawer(
                    child: SideMenu(width: constraints.maxWidth * 0.7),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class RessourceList extends StatelessWidget {
  final bool isMobile;
  const RessourceList({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ressource>>(
      future: fetchRessources(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune ressource trouvée.'));
        }

        final ressources = snapshot.data!;

        return ListView.builder(
          itemCount: ressources.length,
          itemBuilder: (context, index) {
            final ressource = ressources[index];

            return Card(
              margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
              child: ListTile(
                title: Text(
                  ressource.titre,
                  style: TextStyle(fontSize: isMobile ? 16 : 20),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ressource.message,
                      style: TextStyle(fontSize: isMobile ? 13 : 16),
                    ),
                    if (ressource.image != null) ...[
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Image.memory(
                            ressource.image!,
                            height: isMobile ? 120 : 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      'Publié le ${ressource.date.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
