import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pseudoController = TextEditingController();
  final TextEditingController dateNaissanceController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String sexe = "H"; // H = Homme, F = Femme, A = Autre

  final _formKey = GlobalKey<FormState>();

  bool _isValidDate(String input) {
    try {
      final parts = input.split('-');
      if (parts.length != 3) return false;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('http://backend:3000/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nomUtilisateur': nomController.text.trim(),
        'prénomUtilisateur': prenomController.text.trim(),
        'emailUtilisateur': emailController.text.trim(),
        'pseudoUtilisateur': pseudoController.text.trim(),
        'sexeUtilisateur': sexe,
        'dateNaissanceUtilisateur': dateNaissanceController.text.trim(),
        'motDePasseUtilisateur': passwordController.text.trim(),
      }),
    );

    if (response.statusCode == 201) {
      final loginResponse = await http.post(
        Uri.parse('http://backend:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailUtilisateur': emailController.text.trim(),
          'motDePasseUtilisateur': passwordController.text.trim(),
        }),
      );

      if (loginResponse.statusCode == 200) {
        final data = jsonDecode(loginResponse.body)['utilisateur'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', data['id']);
        await prefs.setString('nom', data['nom']);
        await prefs.setString('prénom', data['prénom']);
        await prefs.setString('email', data['email']);
        await prefs.setString('pseudo', data['pseudo']);
        await prefs.setInt('role', data['role']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainApp()),
        );
      } else {
        final error =
            jsonDecode(loginResponse.body)['error'] ??
            'Erreur de connexion après inscription';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur : $error")));
      }
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription'), centerTitle: true),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Container(
              width: isMobile ? double.infinity : constraints.maxWidth * 0.3,
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                      TextFormField(
                        controller: nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: prenomController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prénom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'email est requis';
                          }
                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pseudoController,
                        decoration: const InputDecoration(
                          labelText: 'Pseudo *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le pseudo est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sexe :",
                              style: TextStyle(fontSize: 16),
                            ),
                            Row(
                              children: [
                                Radio<String>(
                                  value: "H",
                                  groupValue: sexe,
                                  onChanged: (value) {
                                    setState(() => sexe = value!);
                                  },
                                ),
                                const Text("Homme"),
                                Radio<String>(
                                  value: "F",
                                  groupValue: sexe,
                                  onChanged: (value) {
                                    setState(() => sexe = value!);
                                  },
                                ),
                                const Text("Femme"),
                                Radio<String>(
                                  value: "A",
                                  groupValue: sexe,
                                  onChanged: (value) {
                                    setState(() => sexe = value!);
                                  },
                                ),
                                const Text("Autre"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dateNaissanceController,
                        decoration: const InputDecoration(
                          labelText: 'Date de naissance (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              !_isValidDate(value.trim())) {
                            return 'Date invalide (format YYYY-MM-DD)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le mot de passe est requis';
                          }
                          if (value.trim().length < 6) {
                            return 'Le mot de passe doit faire au moins 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _register,
                          child: const Text('Créer un compte'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
