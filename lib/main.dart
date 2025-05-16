import 'package:flutter/material.dart';
import 'layout/side-menu.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          final menuWidth = size.width / 6;

          return Scaffold(
            backgroundColor: Colors.grey[200],
            body: Row(
              children: [
                SideMenu(width: menuWidth),
                Expanded(
                  child: Center(
                    child: Text(
                      'Hello World!',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
