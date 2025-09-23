import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './add_user.dart';
import './edit_user.dart';
import 'dart:convert';

// Modèle utilisateur
class UserAdmin {
  final String id;
  final String pseudo;
  final String email;
  final int role;
  final String status; // Nouveau champ

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

    String parseId(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    return UserAdmin(
      id: parseId(json['idUser'] ?? json['idUtilisateur']),
      pseudo: json['pseudo'] ?? json['pseudoUtilisateur'] ?? '',
      email: json['email'] ?? json['emailUtilisateur'] ?? '',
      role: parseRole(json['role'] ?? json['roleUtilisateur']),
      status: json['status'] ?? json['statusUtilisateur'] ?? 'activé',
    );
  }
}

// Récupération des utilisateurs
Future<List<UserAdmin>> fetchUsers() async {
  final response = await http.get(
    Uri.parse('https://chris-crp.freeboxos.fr/api/users'),
  );
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => UserAdmin.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des utilisateurs');
  }
}

// Suppression
Future<void> deleteUser(String id, BuildContext context) async {
  final response = await http.delete(
    Uri.parse('https://chris-crp.freeboxos.fr/api/users/$id'),
  );
  if (response.statusCode == 200) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Utilisateur supprimé')));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur lors de la suppression')),
    );
  }
}

// Activation/désactivation
Future<void> toggleUserStatus(
  String id,
  String currentStatus,
  BuildContext context,
) async {
  final newStatus = currentStatus == 'activé' ? 'désactivé' : 'activé';

  final response = await http.put(
    Uri.parse('https://chris-crp.freeboxos.fr/api/users/$id/status'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'status': newStatus}),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Utilisateur ${newStatus == 'activé' ? 'activé' : 'désactivé'}",
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur lors de la mise à jour du statut")),
    );
  }
}

// Page Admin
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
                      children: [
                        Text(user.email),
                        Text('Rôle : $roleLabel'),
                        Text(
                          'Statut : ${user.status == 'activé' ? 'Activé' : 'Désactivé'}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: "Modifier l'utilisateur",
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EditUserPage(
                                      id: user.id,
                                      pseudo: user.pseudo,
                                      email: user.email,
                                      role: user.role,
                                    ),
                              ),
                            );
                            if (result == true) {
                              setState(() {
                                _usersFuture = fetchUsers();
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Supprimer l'utilisateur",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Confirmation'),
                                    content: Text(
                                      'Voulez-vous vraiment supprimer ${user.pseudo} ?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              await deleteUser(user.id, context);
                              setState(() {
                                _usersFuture = fetchUsers();
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            user.status == 'activé'
                                ? Icons.lock_open
                                : Icons.lock,
                            color:
                                user.status == 'activé'
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                          tooltip:
                              user.status == 'activé'
                                  ? "Désactiver l'utilisateur"
                                  : "Activer l'utilisateur",
                          onPressed: () async {
                            await toggleUserStatus(
                              user.id,
                              user.status,
                              context,
                            );
                            setState(() {
                              _usersFuture = fetchUsers();
                            });
                          },
                        ),
                      ],
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddUserPage()),
              );
              if (result == true) {
                setState(() {
                  _usersFuture = fetchUsers();
                });
              }
            },
            tooltip: "Ajouter un utilisateur",
            child: const Icon(Icons.person_add),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
