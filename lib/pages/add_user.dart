import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import pour le .env

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pseudoController = TextEditingController();
  final TextEditingController dateNaissanceController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String sexe = "H"; // H = Homme, F = Femme, A = Autre
  bool isLoading = false;

  // Validation de la date (YYYY-MM-DD)
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

  // --- SOUMISSION ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // Récupération de l'URL de base depuis le .env
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';
    final url = Uri.parse('$baseUrl/register');

    try {
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

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        _showSnackBar('Utilisateur créé avec succès !', Colors.green);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
        _showSnackBar("Erreur : $error", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Impossible de contacter le serveur. Vérifiez votre connexion.", Colors.red);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Créer un utilisateur'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // Rendu propre sur Web/Desktop
            child: Container(
              padding: const EdgeInsets.all(24),
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
                    const Icon(Icons.person_add_alt_1, size: 60, color: Colors.blueAccent),
                    const SizedBox(height: 24),
                    _buildField(nomController, 'Nom *', Icons.badge),
                    _buildField(prenomController, 'Prénom *', Icons.badge_outlined),
                    _buildField(emailController, 'Email *', Icons.email, type: TextInputType.emailAddress),
                    _buildField(pseudoController, 'Pseudo *', Icons.account_circle),
                    
                    // --- SÉLECTION DU SEXE ---
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Sexe :", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildRadio("H", "Homme"),
                              _buildRadio("F", "Femme"),
                              _buildRadio("A", "Autre"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    _buildField(dateNaissanceController, 'Date de naissance (YYYY-MM-DD)', Icons.calendar_today, 
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty && !_isValidDate(value.trim())) {
                          return 'Format YYYY-MM-DD requis';
                        }
                        return null;
                      }
                    ),
                    _buildField(passwordController, 'Mot de passe *', Icons.lock, obscure: true),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle),
                        label: const Text('CRÉER LE COMPTE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION ---
  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text, bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator ?? (value) => value == null || value.trim().isEmpty ? 'Ce champ est requis' : null,
      ),
    );
  }

  Widget _buildRadio(String value, String label) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: sexe,
          onChanged: (val) => setState(() => sexe = val!),
        ),
        Text(label),
      ],
    );
  }
}