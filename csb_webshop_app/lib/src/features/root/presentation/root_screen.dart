import 'package:flutter/material.dart';

import '../../bags/presentation/bags_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.title});

  final String title;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const BagsListScreen(),
      ProfileScreen(title: widget.title),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (int i) => setState(() => _index = i),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Katalog'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

