import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import indispensable

class ProfilUserPage extends StatefulWidget {
  final String userId;

  const ProfilUserPage({super.key, required this.userId});

  @override
  State<ProfilUserPage> createState() => _ProfilUserPageState();
}

class _ProfilUserPageState extends State<ProfilUserPage> {
  final _formKey = GlobalKey<FormState>();

  // Champs utilisateur
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pseudoController = TextEditingController();
  final TextEditingController sexeController = TextEditingController();
  final TextEditingController motDePasseController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // --- RÉCUPÉRATION DES DONNÉES ---
  Future<void> fetchUserData() async {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final user = json.decode(response.body);
        setState(() {
          nomController.text = user['nom'] ?? '';
          prenomController.text = user['prénom'] ?? '';
          emailController.text = user['email'] ?? '';
          pseudoController.text = user['pseudo'] ?? '';
          sexeController.text = user['sexe'] ?? '';
          motDePasseController.text = user['motDePasse'] ?? '';
          isLoading = false;
        });
      } else {
        _showSnackBar("Erreur lors du chargement des données.");
      }
    } catch (e) {
      _showSnackBar("Impossible de contacter le serveur.");
    }
  }

  // --- MISE À JOUR DES DONNÉES ---
  Future<void> updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nom': nomController.text,
          'prénom': prenomController.text,
          'email': emailController.text,
          'pseudo': pseudoController.text,
          'sexe': sexeController.text,
          'motDePasse': motDePasseController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Profil mis à jour avec succès.");
      } else {
        _showSnackBar("Erreur lors de la mise à jour.");
      }
    } catch (e) {
      _showSnackBar("Erreur réseau : mise à jour impossible.");
    }
  }

  // Helper pour afficher les messages
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profil Utilisateur"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueGrey,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    buildTextField("Nom", nomController),
                    buildTextField("Prénom", prenomController),
                    buildTextField("Email", emailController, keyboardType: TextInputType.emailAddress),
                    buildTextField("Pseudo", pseudoController),
                    buildTextField("Sexe", sexeController),
                    buildTextField(
                      "Mot de passe",
                      motDePasseController,
                      obscure: true,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: updateUserData,
                        child: const Text("Enregistrer les modifications", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Ce champ est obligatoire";
          }
          return null;
        },
      ),
    );
  }
}