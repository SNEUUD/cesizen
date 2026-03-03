import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import crucial

class AddRessourcePage extends StatefulWidget {
  const AddRessourcePage({super.key});

  @override
  State<AddRessourcePage> createState() => _AddRessourcePageState();
}

class _AddRessourcePageState extends State<AddRessourcePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titreController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  Uint8List? imageBytes;
  bool isLoading = false;

  // --- LOGIQUE API ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // Récupération de l'URL de base depuis le .env
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

    final Map<String, dynamic> body = {
      'titreRessource': titreController.text.trim(),
      'descriptionRessource': messageController.text.trim(),
      'dateRessource': DateTime.now().toIso8601String(),
      'imageRessource': imageBytes != null ? base64Encode(imageBytes!) : null,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_ressource'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        _showSnackBar('Ressource ajoutée avec succès !', Colors.green);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Inconnue';
        _showSnackBar('Erreur : $error', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Impossible de contacter le serveur', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- SÉLECTION D'IMAGE ---
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, // Optimisation pour éviter les images trop lourdes sur le RPi
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageBytes = bytes;
      });
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
        title: const Text('Ajouter une ressource'),
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
                  const Icon(Icons.post_add, size: 64, color: Colors.blueAccent),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: titreController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la ressource',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Titre requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Description / Contenu',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 5,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Description requise' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // --- SECTION IMAGE ---
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: pickImage,
                                icon: const Icon(Icons.image_search),
                                label: const Text('Sélectionner une image'),
                              ),
                              if (imageBytes != null) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.check_circle, color: Colors.green),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => setState(() => imageBytes = null),
                                )
                              ],
                            ],
                          ),
                          if (imageBytes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  imageBytes!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.publish),
                      label: const Text('PUBLIER LA RESSOURCE', style: TextStyle(fontWeight: FontWeight.bold)),
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