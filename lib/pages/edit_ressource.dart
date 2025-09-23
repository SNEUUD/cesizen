import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final Map<String, dynamic> body = {
      'titreRessource': titreController.text,
      'descriptionRessource': messageController.text,
      'imageRessource': imageBytes != null ? base64Encode(imageBytes!) : null,
    };
    final response = await http.put(
      Uri.parse('http://chris-crp.freeboxos.fr:3050/ressources/${widget.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    setState(() => isLoading = false);
    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ressource modifiée avec succès !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : ${jsonDecode(response.body)['error'] ?? 'Inconnue'}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la ressource')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Titre requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Description requise'
                            : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Changer l\'image'),
                  ),
                  const SizedBox(width: 12),
                  if (imageBytes != null)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        if (widget.userRole == 2)
                          IconButton(
                            tooltip: "Supprimer l'image",
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                imageBytes = null;
                              });
                            },
                          ),
                      ],
                    ),
                ],
              ),
              if (imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Image.memory(
                    imageBytes!,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
