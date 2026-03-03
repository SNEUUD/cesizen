import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import crucial
import 'add_ressources.dart'; 
import 'edit_ressource.dart';

// --- MODÈLE ---
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
      // Note : J'ai gardé 'descriptionRessource' comme dans ton dernier message
      message: json['descriptionRessource'] ?? '', 
      date: DateTime.parse(json['dateRessource']),
      image: json['imageRessource'] != null
          ? base64Decode(json['imageRessource'])
          : null,
    );
  }
}

// --- LOGIQUE API ---

Future<List<Ressource>> fetchRessources() async {
  // Récupération de l'URL depuis le .env
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

  final response = await http.get(
    Uri.parse('$baseUrl/ressources'),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Ressource.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des ressources');
  }
}

Future<void> deleteRessource(int id, BuildContext context) async {
  // Récupération de l'URL depuis le .env
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

  final response = await http.delete(
    Uri.parse('$baseUrl/ressources/$id'),
  );

  if (response.statusCode != 200) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }
}

// --- INTERFACE ---

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
    setState(() {
      _ressourcesFuture = fetchRessources();
    });
  }

  Future<void> _deleteAndRefresh(int id) async {
    await deleteRessource(id, context);
    _loadRessources();
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
                            style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                ressource.message,
                                style: TextStyle(fontSize: isMobile ? 13 : 16),
                              ),
                              if (ressource.image != null) ...[
                                const SizedBox(height: 10),
                                Center(
                                  child: Image.memory(
                                    ressource.image!,
                                    height: isMobile ? 150 : 300,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Publié le ${ressource.date.day}/${ressource.date.month}/${ressource.date.year}',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: widget.userRole == 2 
                            ? _buildAdminActions(ressource) 
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
        // Bouton flottant uniquement pour les admins (Rôle 2)
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
                if (result == true) _loadRessources();
              },
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminActions(Ressource ressource) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditRessourcePage(
                  id: ressource.id,
                  titre: ressource.titre,
                  message: ressource.message,
                  image: ressource.image,
                  userRole: widget.userRole,
                ),
              ),
            );
            if (result == true) _loadRessources();
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteDialog(ressource.id),
        ),
      ],
    );
  }

  void _showDeleteDialog(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Supprimer cette ressource ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Supprimer', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteAndRefresh(id);
  }
}