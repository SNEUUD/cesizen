import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Rapport {
  final int id;
  final String titre;
  final String message;
  final DateTime date;

  Rapport({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
  });

  factory Rapport.fromJson(Map<String, dynamic> json) {
    return Rapport(
      id: json['idRapport'],
      titre: json['titreRapport'],
      message: json['messageRapport'],
      date: DateTime.parse(json['dateRapport']),
    );
  }
}

Future<List<Rapport>> fetchRapports(String userId) async {
  final response = await http.get(
    Uri.parse('http://0.0.0.0:3050/rapports_user?userId=$userId'),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Rapport.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des rapports');
  }
}

class RapportsPage extends StatelessWidget {
  final bool isMobile;
  final String userId;

  const RapportsPage({Key? key, required this.userId, this.isMobile = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Rapport>>(
      future: fetchRapports(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun rapport trouvé.'));
        }

        final rapports = snapshot.data!;

        return ListView.builder(
          itemCount: rapports.length,
          itemBuilder: (context, index) {
            final rapport = rapports[index];

            return Card(
              margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
              child: ListTile(
                title: Text(
                  rapport.titre,
                  style: TextStyle(fontSize: isMobile ? 16 : 20),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rapport.message,
                      style: TextStyle(fontSize: isMobile ? 13 : 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Publié le ${rapport.date.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
