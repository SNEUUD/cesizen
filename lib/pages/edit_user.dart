import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import pour le .env

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

    // Récupération de l'URL depuis le .env
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';
    final url = Uri.parse('$baseUrl/users/${widget.id}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pseudo': pseudoController.text.trim(),
          'email': emailController.text.trim(),
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
        _showSnackBar('Utilisateur modifié avec succès !', Colors.green);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
        _showSnackBar("Erreur : $error", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Impossible de joindre le serveur", Colors.red);
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
      appBar: AppBar(
        title: const Text('Modifier un utilisateur'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // Pour un rendu propre sur Desktop/Web
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.manage_accounts, size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: pseudoController,
                    decoration: const InputDecoration(
                      labelText: 'Pseudo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Pseudo requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Email requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Rôle système',
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Utilisateur Standard')),
                      DropdownMenuItem(value: 2, child: Text('Administrateur')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => role = value);
                    },
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
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