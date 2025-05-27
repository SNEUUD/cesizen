import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Modèle Ressource (à déplacer ici ou à importer)
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
      message: json['descriptionRessource'],
      date: DateTime.parse(json['dateRessource']),
      image: json['imageRessource'] != null
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

class RessourcesPage extends StatelessWidget {
  final bool isMobile;
  const RessourcesPage({super.key, this.isMobile = false});

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