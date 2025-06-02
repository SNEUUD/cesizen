import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Modèle utilisateur
class UserAdmin {
  final int id;
  final String pseudo;
  final String email;
  final int role;

  UserAdmin({
    required this.id,
    required this.pseudo,
    required this.email,
    required this.role,
  });

  factory UserAdmin.fromJson(Map<String, dynamic> json) {
    int parseRole(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 1;
      return 1;
    }

    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return UserAdmin(
      id: parseId(json['idUser'] ?? json['idUtilisateur']),
      pseudo: json['pseudo'] ?? json['pseudoUtilisateur'] ?? '',
      email: json['email'] ?? json['emailUtilisateur'] ?? '',
      role: parseRole(json['role'] ?? json['roleUtilisateur']),
    );
  }
}

Future<List<UserAdmin>> fetchUsers() async {
  final response = await http.get(Uri.parse('http://0.0.0.0:3050/users'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => UserAdmin.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des utilisateurs');
  }
}

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
    _usersFuture = fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
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
                String roleLabel =
                    user.role == 2 ? 'Administrateur' : 'Utilisateur';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.pseudo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(user.email), Text('Rôle : $roleLabel')],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 32.0, bottom: 16.0),
          child: FloatingActionButton(
            onPressed: () {
              // TODO: Naviguer vers la page d'ajout d'utilisateur
            },
            child: const Icon(Icons.person_add),
            tooltip: "Ajouter un utilisateur",
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
