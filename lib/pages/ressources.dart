import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_ressources.dart'; // Ajoute cet import en haut du fichier
import 'edit_ressource.dart';

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
      image:
          json['imageRessource'] != null
              ? base64Decode(json['imageRessource'])
              : null,
    );
  }
}

Future<List<Ressource>> fetchRessources() async {
  final response = await http.get(
    Uri.parse('https://chris-crp.freeboxos.fr/api/ressources'),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Ressource.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des ressources');
  }
}

Future<void> deleteRessource(int id, BuildContext context) async {
  final response = await http.delete(
    Uri.parse('https://chris-crp.freeboxos.fr/api/ressources/$id'),
  );
  if (response.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur lors de la suppression de la ressource'),
      ),
    );
  }
}

class RessourcesPage extends StatefulWidget {
  final bool isMobile;
  final int userRole;

  const RessourcesPage({
    super.key,
    this.isMobile = false,
    required this.userRole,
  });

  @override
  State<RessourcesPage> createState() => _RessourcesPageState();
}

class _RessourcesPageState extends State<RessourcesPage> {
  late Future<List<Ressource>> _ressourcesFuture;

  @override
  void initState() {
    super.initState();
    _loadRessources();
  }

  void _loadRessources() {
    _ressourcesFuture = fetchRessources();
  }

  Future<void> _deleteAndRefresh(int id) async {
    await deleteRessource(id, context);
    setState(() {
      _loadRessources();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 24, left: 16, bottom: 8),
              child: Text(
                "Ressources",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Ressource>>(
                future: _ressourcesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aucune ressource trouvée.'),
                    );
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
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 8,
                                    ),
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
                          trailing:
                              widget.userRole == 2
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        tooltip: "Modifier la ressource",
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => EditRessourcePage(
                                                    id: ressource.id,
                                                    titre: ressource.titre,
                                                    message: ressource.message,
                                                    image: ressource.image,
                                                    userRole: widget.userRole,
                                                  ),
                                            ),
                                          );
                                          if (result == true) {
                                            setState(() {
                                              _loadRessources();
                                            });
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: "Supprimer la ressource",
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'Confirmation',
                                                  ),
                                                  content: const Text(
                                                    'Voulez-vous vraiment supprimer cette ressource ?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            ctx,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Annuler',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            ctx,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Supprimer',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                          if (confirm == true) {
                                            await _deleteAndRefresh(
                                              ressource.id,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                  : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        if (widget.userRole == 2)
          Positioned(
            bottom: 24,
            left: 24,
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddRessourcePage()),
                );
                if (result == true) {
                  setState(() {
                    _loadRessources();
                  });
                }
              },
              tooltip: "Nouvelle ressource",
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}
