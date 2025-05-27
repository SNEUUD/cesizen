import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_rapport.dart';

class Emotion {
  final int id;
  final String intitule;

  Emotion({required this.id, required this.intitule});

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      id: json['idEmotion'],
      intitule: json['IntituleEmotion'],
    );
  }
}

class Rapport {
  final int id;
  final String titre;
  final String message;
  final int emotion; // id de l'émotion
  final DateTime date;

  Rapport({
    required this.id,
    required this.titre,
    required this.message,
    required this.emotion,
    required this.date,
  });

  factory Rapport.fromJson(Map<String, dynamic> json) {
    return Rapport(
      id: json['idRapport'],
      titre: json['titreRapport'],
      message: json['messageRapport'],
      emotion: int.tryParse(json['emotionRapport'].toString()) ?? 0,
      date: DateTime.parse(json['dateRapport']),
    );
  }
}

Future<List<Rapport>> fetchRapports(String userId) async {
  final response = await http.get(
    Uri.parse('http://0.0.0.0:3050/rapports_user?userId=$userId'),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Rapport.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des rapports');
  }
}

Future<List<Emotion>> fetchEmotions() async {
  final response = await http.get(Uri.parse('http://0.0.0.0:3050/emotions'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Emotion.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des émotions');
  }
}

class RapportsPage extends StatelessWidget {
  final bool isMobile;
  final String userId;

  const RapportsPage({Key? key, required this.userId, this.isMobile = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Emotion>>(
          future: fetchEmotions(),
          builder: (context, emotionsSnapshot) {
            if (emotionsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (emotionsSnapshot.hasError) {
              return Center(child: Text('Erreur: ${emotionsSnapshot.error}'));
            } else if (!emotionsSnapshot.hasData || emotionsSnapshot.data!.isEmpty) {
              return const Center(child: Text('Aucune émotion trouvée.'));
            }

            final emotions = emotionsSnapshot.data!;
            // Création d'une map id -> intitulé pour accès rapide
            final emotionMap = {for (var e in emotions) e.id: e.intitule};

            return FutureBuilder<List<Rapport>>(
              future: fetchRapports(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun rapport trouvé.'));
                }

                final rapports = snapshot.data!;

                return ListView.builder(
                  itemCount: rapports.length,
                  itemBuilder: (context, index) {
                    final rapport = rapports[index];
                    final emotionLabel = emotionMap[rapport.emotion] ?? 'Inconnu';

                    return Card(
                      margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
                      child: ListTile(
                        title: Text(
                          rapport.titre,
                          style: TextStyle(fontSize: isMobile ? 16 : 20),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rapport.message,
                              style: TextStyle(fontSize: isMobile ? 13 : 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Émotion : $emotionLabel',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.blueGrey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Publié le ${rapport.date.toLocal().toString().split(' ')[0]}',
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
          },
        ),
        Positioned(
          bottom: 24,
          left: 24,
          child: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRapportPage(userId: userId),
                ),
              );
              if (result == true) {
                (context as Element).reassemble();
              }
            },
            child: const Icon(Icons.add),
            tooltip: "Nouveau Rapport",
          ),
        ),
      ],
    );
  }
}
