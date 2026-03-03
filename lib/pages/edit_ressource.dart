import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import pour le .env

class EditRessourcePage extends StatefulWidget {
  final int id;
  final String titre;
  final String message;
  final Uint8List? image;
  final int userRole;

  const EditRessourcePage({
    super.key,
    required this.id,
    required this.titre,
    required this.message,
    this.image,
    required this.userRole,
  });

  @override
  State<EditRessourcePage> createState() => _EditRessourcePageState();
}

class _EditRessourcePageState extends State<EditRessourcePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titreController;
  late TextEditingController messageController;
  Uint8List? imageBytes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titreController = TextEditingController(text: widget.titre);
    messageController = TextEditingController(text: widget.message);
    imageBytes = widget.image;
  }

  // --- SÉLECTION D'IMAGE ---
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageBytes = bytes;
      });
    }
  }

  // --- SOUMISSION DU FORMULAIRE ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    // Récupération de l'URL depuis le .env
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

    final Map<String, dynamic> body = {
      'titreRessource': titreController.text.trim(),
      'descriptionRessource': messageController.text.trim(),
      'imageRessource': imageBytes != null ? base64Encode(imageBytes!) : null,
    };

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/ressources/${widget.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
        _showSnackBar('Ressource modifiée avec succès !', Colors.green);
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

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la ressource')),
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
                  TextFormField(
                    controller: titreController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la ressource',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Titre requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Description / Message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) => value == null || value.isEmpty ? 'Description requise' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // --- SECTION IMAGE ---
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
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
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Changer l\'image'),
                              ),
                              if (imageBytes != null && widget.userRole == 2) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: "Supprimer l'image",
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  onPressed: () => setState(() => imageBytes = null),
                                ),
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
                      ),
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: const Text('ENREGISTRER LES MODIFICATIONS'),
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