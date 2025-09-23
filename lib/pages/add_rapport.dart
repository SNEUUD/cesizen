import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> fetchEmotions() async {
    final response = await http.get(
      Uri.parse('https://chris-crp.freeboxos.fr:3050/emotions'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final List<Emotion> loadedEmotions =
          data.map((json) => Emotion.fromJson(json)).toList();
      loadedEmotions.sort(
        (a, b) => a.intitule
            .substring(2)
            .toLowerCase()
            .compareTo(b.intitule.substring(2).toLowerCase()),
      );
      setState(() {
        emotions = loadedEmotions;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedEmotion == null) return;

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('https://chris-crp.freeboxos.fr:3050/add_rapports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titreRapport': titreController.text,
        'messageRapport': messageController.text,
        'userRapport': widget.userId,
        'emotionRapport': selectedEmotion!.id, // On envoie l'id de l'émotion
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 201) {
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapport ajouté avec succès !')),
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
      appBar: AppBar(title: const Text('Ajouter un rapport')),
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
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Message requis'
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Emotion>(
                value: selectedEmotion,
                decoration: const InputDecoration(
                  labelText: 'Émotion',
                  border: OutlineInputBorder(),
                ),
                items:
                    emotions
                        .map(
                          (emotion) => DropdownMenuItem(
                            value: emotion,
                            child: Text(emotion.intitule),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEmotion = value;
                  });
                },
                validator: (value) => value == null ? 'Émotion requise' : null,
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
                          : const Icon(Icons.send),
                  label: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
