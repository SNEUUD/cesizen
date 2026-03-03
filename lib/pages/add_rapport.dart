import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import crucial pour le .env

class Emotion {
  final int id;
  final String intitule;

  Emotion({required this.id, required this.intitule});

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(id: json['idEmotion'], intitule: json['IntituleEmotion']);
  }
}

class AddRapportPage extends StatefulWidget {
  final String userId;
  const AddRapportPage({super.key, required this.userId});

  @override
  State<AddRapportPage> createState() => _AddRapportPageState();
}

class _AddRapportPageState extends State<AddRapportPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titreController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  Emotion? selectedEmotion;
  bool isLoading = false;
  List<Emotion> emotions = [];

  @override
  void initState() {
    super.initState();
    fetchEmotions();
  }

  // --- RÉCUPÉRATION DES ÉMOTIONS ---
  Future<void> fetchEmotions() async {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/emotions'));
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final List<Emotion> loadedEmotions = data.map((json) => Emotion.fromJson(json)).toList();
        
        // Ta logique de tri (ignore les 2 premiers caractères)
        loadedEmotions.sort(
          (a, b) => a.intitule.substring(2).toLowerCase().compareTo(b.intitule.substring(2).toLowerCase()),
        );

        if (mounted) {
          setState(() {
            emotions = loadedEmotions;
          });
        }
      }
    } catch (e) {
      _showSnackBar("Erreur lors du chargement des émotions", Colors.orange);
    }
  }

  // --- SOUMISSION DU RAPPORT ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedEmotion == null) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.orange);
      return;
    }

    setState(() => isLoading = true);
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_rapports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titreRapport': titreController.text.trim(),
          'messageRapport': messageController.text.trim(),
          'userRapport': widget.userId,
          'emotionRapport': selectedEmotion!.id,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        _showSnackBar('Rapport ajouté avec succès !', Colors.green);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Inconnue';
        _showSnackBar('Erreur : $error', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur réseau : impossible d\'ajouter le rapport', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Nouveau Rapport'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: titreController,
                    decoration: const InputDecoration(
                      labelText: 'Titre du rapport',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Titre requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Comment vous sentez-vous ?',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 5,
                    validator: (value) => value == null || value.isEmpty ? 'Message requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Emotion>(
                    value: selectedEmotion,
                    decoration: const InputDecoration(
                      labelText: 'Émotion dominante',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mood),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: emotions.map((emotion) => DropdownMenuItem(
                      value: emotion,
                      child: Text(emotion.intitule),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedEmotion = value),
                    validator: (value) => value == null ? 'Émotion requise' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle),
                      label: const Text('ENREGISTRER LE RAPPORT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}