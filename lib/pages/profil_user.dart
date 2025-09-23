import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilUserPage extends StatefulWidget {
  final String userId;

  const ProfilUserPage({super.key, required this.userId});

  @override
  State<ProfilUserPage> createState() => _ProfilUserPageState();
}

class _ProfilUserPageState extends State<ProfilUserPage> {
  final _formKey = GlobalKey<FormState>();

  // Champs utilisateur
  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController pseudoController = TextEditingController();
  TextEditingController sexeController = TextEditingController();
  // Supprimé : TextEditingController dateNaissanceController = TextEditingController();
  TextEditingController motDePasseController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final response = await http.get(
      Uri.parse('https://chris-crp.freeboxos.fr:3050/user/${widget.userId}'),
    );
    if (response.statusCode == 200) {
      final user = json.decode(response.body);
      setState(() {
        nomController.text = user['nom'] ?? '';
        prenomController.text = user['prénom'] ?? '';
        emailController.text = user['email'] ?? '';
        pseudoController.text = user['pseudo'] ?? '';
        sexeController.text = user['sexe'] ?? '';
        // Supprimé : dateNaissanceController.text = user['dateNaissance'] ?? '';
        motDePasseController.text = user['motDePasse'] ?? '';
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des données.")),
      );
    }
  }

  Future<void> updateUserData() async {
    final response = await http.put(
      Uri.parse('https://chris-crp.freeboxos.fr:3050/user/${widget.userId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nom': nomController.text,
        'prénom': prenomController.text,
        'email': emailController.text,
        'pseudo': pseudoController.text,
        'sexe': sexeController.text,
        // Supprimé : 'dateNaissance': formattedDate,
        'motDePasse': motDePasseController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profil mis à jour avec succès.")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lors de la mise à jour.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Utilisateur"),
        centerTitle: true,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Icon(Icons.person, size: 100, color: Colors.grey),
                      const SizedBox(height: 20),
                      buildTextField("Nom", nomController),
                      buildTextField("Prénom", prenomController),
                      buildTextField("Email", emailController),
                      buildTextField("Pseudo", pseudoController),
                      buildTextField("Sexe", sexeController),
                      // Supprimé champ date de naissance
                      buildTextField(
                        "Mot de passe",
                        motDePasseController,
                        obscure: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: updateUserData,
                        child: const Text("Mettre à jour"),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  // Supprimé Widget buildDatePickerField
}
