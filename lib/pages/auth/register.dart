import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import pour le .env
import '../../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pseudoController = TextEditingController();
  final TextEditingController dateNaissanceController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String sexe = "H"; 
  bool isLoading = false;

  // Validation format de date
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

  // --- LOGIQUE D'INSCRIPTION ---
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';

    try {
      // 1. Appel à l'inscription
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
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
        // 2. Connexion automatique après inscription réussie
        final loginResponse = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'emailUtilisateur': emailController.text.trim(),
            'motDePasseUtilisateur': passwordController.text.trim(),
          }),
        );

        if (loginResponse.statusCode == 200) {
          final data = jsonDecode(loginResponse.body)['utilisateur'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('id', data['id'].toString());
          await prefs.setString('nom', data['nom'] ?? '');
          await prefs.setString('prénom', data['prénom'] ?? '');
          await prefs.setString('email', data['email'] ?? '');
          await prefs.setString('pseudo', data['pseudo'] ?? '');
          await prefs.setInt('role', data['role'] ?? 1);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainApp()),
          );
        } else {
          _showSnackBar("Inscription réussie, mais connexion automatique échouée.");
        }
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
        _showSnackBar("Erreur : $error");
      }
    } catch (e) {
      _showSnackBar("Erreur réseau : impossible de joindre le serveur.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Inscription'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Container(
                width: isMobile ? double.infinity : 500,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.person_add, size: 60)),
                      const SizedBox(height: 24),
                      _buildTextField(nomController, 'Nom *'),
                      _buildTextField(prenomController, 'Prénom *'),
                      _buildTextField(emailController, 'Email *', keyboard: TextInputType.emailAddress),
                      _buildTextField(pseudoController, 'Pseudo *'),
                      
                      const SizedBox(height: 16),
                      _buildSexeSelector(),
                      const SizedBox(height: 16),

                      _buildTextField(dateNaissanceController, 'Date de naissance (YYYY-MM-DD)', 
                        validator: (v) => (v != null && v.isNotEmpty && !_isValidDate(v)) ? 'Format YYYY-MM-DD requis' : null
                      ),
                      _buildTextField(passwordController, 'Mot de passe *', obscure: true),
                      
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isLoading ? null : _register,
                          child: isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('CRÉER MON COMPTE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscure = false, TextInputType keyboard = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator ?? (value) => (value == null || value.trim().isEmpty) ? 'Ce champ est requis' : null,
      ),
    );
  }

  Widget _buildSexeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sexe :", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Radio<String>(value: "H", groupValue: sexe, onChanged: (v) => setState(() => sexe = v!)),
            const Text("H"),
            Radio<String>(value: "F", groupValue: sexe, onChanged: (v) => setState(() => sexe = v!)),
            const Text("F"),
            Radio<String>(value: "A", groupValue: sexe, onChanged: (v) => setState(() => sexe = v!)),
            const Text("Autre"),
          ],
        ),
      ],
    );
  }
}