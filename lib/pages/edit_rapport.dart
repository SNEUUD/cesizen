import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

    final url = Uri.parse(
      'http://backend:3000/edit_rapports/${widget.rapport.id}',
    );
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titreRapport': _titreController.text,
        'messageRapport': _messageController.text,
        'emotionRapport': _selectedEmotionId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapport mis à jour avec succès')),
      );
      Navigator.pop(context, true); // Signale un rafraîchissement nécessaire
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le rapport')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) => value!.isEmpty ? 'Titre requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Message requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedEmotionId,
                items:
                    widget.emotions.map((emotion) {
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
                decoration: const InputDecoration(labelText: 'Émotion'),
                validator: (value) => value == null ? 'Émotion requise' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
