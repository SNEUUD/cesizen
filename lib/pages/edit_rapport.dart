import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import pour le .env
import 'rapports.dart';

class EditRapportPage extends StatefulWidget {
  final Rapport rapport;
  final List<Emotion> emotions;

  const EditRapportPage({
    super.key,
    required this.rapport,
    required this.emotions,
  });

  @override
  State<EditRapportPage> createState() => _EditRapportPageState();
}

class _EditRapportPageState extends State<EditRapportPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _messageController;
  int? _selectedEmotionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.rapport.titre);
    _messageController = TextEditingController(text: widget.rapport.message);
    _selectedEmotionId = widget.rapport.emotion;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Récupération de l'URL de base depuis le .env
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';
    final url = Uri.parse('$baseUrl/edit_rapports/${widget.rapport.id}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titreRapport': _titreController.text.trim(),
          'messageRapport': _messageController.text.trim(),
          'emotionRapport': _selectedEmotionId,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourne true pour rafraîchir la liste
      } else {
        _showErrorSnackBar('Erreur lors de la mise à jour (Code: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Impossible de contacter le serveur. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le rapport'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.edit_note, size: 60, color: Colors.blueGrey),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titreController,
                    decoration: const InputDecoration(
                      labelText: 'Titre du rapport',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) => value!.isEmpty ? 'Titre requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Votre message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    validator: (value) => value!.isEmpty ? 'Message requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedEmotionId,
                    items: widget.emotions.map((emotion) {
                      return DropdownMenuItem<int>(
                        value: emotion.id,
                        child: Text(emotion.intitule),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEmotionId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Émotion associée',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mood),
                    ),
                    validator: (value) => value == null ? 'Émotion requise' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('ENREGISTRER LES MODIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold)),
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