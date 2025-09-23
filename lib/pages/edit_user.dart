import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditUserPage extends StatefulWidget {
  final String id;
  final String pseudo;
  final String email;
  final int role;

  const EditUserPage({
    super.key,
    required this.id,
    required this.pseudo,
    required this.email,
    required this.role,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController pseudoController;
  late TextEditingController emailController;
  late int role;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    pseudoController = TextEditingController(text: widget.pseudo);
    emailController = TextEditingController(text: widget.email);
    role = widget.role;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url = Uri.parse(
      'http://chris-crp.freeboxos.fr:3050/users/${widget.id}',
    );
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pseudo': pseudoController.text.trim(),
        'email': emailController.text.trim(),
        'role': role,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur modifié avec succès !')),
      );
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier un utilisateur')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pseudoController,
                decoration: const InputDecoration(
                  labelText: 'Pseudo',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Pseudo requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Email requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Utilisateur')),
                  DropdownMenuItem(value: 2, child: Text('Administrateur')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => role = value);
                },
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
