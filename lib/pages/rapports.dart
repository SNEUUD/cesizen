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

/// Supprime un rapport via une requête HTTP DELETE
Future<void> deleteRapport(int id, BuildContext context) async {
  final response = await http.delete(
    Uri.parse('http://0.0.0.0:3050/rapports/$id'),
  );
  if (response.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur lors de la suppression du rapport')),
    );
    throw Exception('Erreur lors de la suppression du rapport');
  }
}

class RapportsPage extends StatefulWidget {
  final bool isMobile;
  final String userId;

  const RapportsPage({Key? key, required this.userId, this.isMobile = false})
      : super(key: key);

  @override
  State<RapportsPage> createState() => _RapportsPageState();
}

class _RapportsPageState extends State<RapportsPage> {
  Future<List<Rapport>>? _rapportsFuture;
  Future<List<Emotion>>? _emotionsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _rapportsFuture = fetchRapports(widget.userId);
    _emotionsFuture = fetchEmotions();
  }

  Future<void> _deleteAndRefresh(int id) async {
    await deleteRapport(id, context);
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 24, left: 16, bottom: 8),
          child: Text(
            "Rapports",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FutureBuilder<List<Emotion>>(
                future: _emotionsFuture,
                builder: (context, emotionsSnapshot) {
                  if (emotionsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (emotionsSnapshot.hasError) {
                    return Center(child: Text('Erreur: ${emotionsSnapshot.error}'));
                  } else if (!emotionsSnapshot.hasData || emotionsSnapshot.data!.isEmpty) {
                    return const Center(child: Text('Aucune émotion trouvée.'));
                  }

                  final emotions = emotionsSnapshot.data!;
                  final emotionMap = {for (var e in emotions) e.id: e.intitule};

                  return FutureBuilder<List<Rapport>>(
                    future: _rapportsFuture,
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
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: "Supprimer",
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirmation'),
                                      content: const Text('Voulez-vous vraiment supprimer ce rapport ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _deleteAndRefresh(rapport.id);
                                  }
                                },
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
                        builder: (context) => AddRapportPage(userId: widget.userId),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        _loadData();
                      });
                    }
                  },
                  child: const Icon(Icons.add),
                  tooltip: "Nouveau Rapport",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
