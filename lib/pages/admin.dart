import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import pour le .env
import './add_user.dart';
import './edit_user.dart';

// --- MODÈLE ---
class UserAdmin {
  final String id;
  final String pseudo;
  final String email;
  final int role;
  final String status;

  UserAdmin({
    required this.id,
    required this.pseudo,
    required this.email,
    required this.role,
    required this.status,
  });

  factory UserAdmin.fromJson(Map<String, dynamic> json) {
    int parseRole(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 1;
      return 1;
    }

    return UserAdmin(
      id: (json['idUser'] ?? json['idUtilisateur'] ?? '').toString(),
      pseudo: json['pseudo'] ?? json['pseudoUtilisateur'] ?? '',
      email: json['email'] ?? json['emailUtilisateur'] ?? '',
      role: parseRole(json['role'] ?? json['roleUtilisateur']),
      status: json['status'] ?? json['statusUtilisateur'] ?? 'activé',
    );
  }
}

// --- LOGIQUE API ---

Future<List<UserAdmin>> fetchUsers() async {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';
  
  final response = await http.get(Uri.parse('$baseUrl/users'));
  
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => UserAdmin.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des utilisateurs');
  }
}

Future<void> deleteUser(String id, BuildContext context) async {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';
  
  final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
  
  if (!context.mounted) return;

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur supprimé')));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la suppression')));
  }
}

Future<void> toggleUserStatus(String id, String currentStatus, BuildContext context) async {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://chris-crp.freeboxos.fr/api';
  final newStatus = currentStatus == 'activé' ? 'désactivé' : 'activé';

  try {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Utilisateur $newStatus")),
      );
    } else {
      throw Exception();
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour du statut")),
      );
    }
  }
}

// --- INTERFACE ---

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<UserAdmin>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<UserAdmin>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Aucun utilisateur trouvé.'));
            }

            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserPage()),
          );
          if (result == true) _loadUsers();
        },
        label: const Text("Nouvel Utilisateur"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildUserCard(UserAdmin user) {
    bool isActivated = user.status == 'activé';
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActivated ? Colors.blue[100] : Colors.grey[300],
          child: Icon(Icons.person, color: isActivated ? Colors.blue : Colors.grey),
        ),
        title: Text(user.pseudo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('Rôle : ${user.role == 2 ? 'Administrateur' : 'Utilisateur'}', 
                 style: const TextStyle(fontStyle: FontStyle.italic)),
            Text('Statut : ${isActivated ? 'Activé' : 'Désactivé'}',
                 style: TextStyle(color: isActivated ? Colors.green : Colors.red, fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditUserPage(
                      id: user.id,
                      pseudo: user.pseudo,
                      email: user.email,
                      role: user.role,
                    ),
                  ),
                );
                if (result == true) _loadUsers();
              },
            ),
            IconButton(
              icon: Icon(isActivated ? Icons.lock_open : Icons.lock, 
                         color: isActivated ? Colors.green : Colors.orange),
              onPressed: () async {
                await toggleUserStatus(user.id, user.status, context);
                _loadUsers();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(user),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserAdmin user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet utilisateur ?'),
        content: Text('Cette action est irréversible pour ${user.pseudo}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await deleteUser(user.id, context);
      _loadUsers();
    }
  }
}