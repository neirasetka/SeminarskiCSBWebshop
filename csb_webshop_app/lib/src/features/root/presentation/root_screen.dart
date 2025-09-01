import 'package:flutter/material.dart';

import '../../bags/presentation/bags_list_screen.dart';
import '../../belts/presentation/belts_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../orders/presentation/cart_screen.dart';
import '../../../core/notification_service.dart';

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
      const BeltsListScreen(),
      const CartScreen(),
      ProfileScreen(title: widget.title),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Demo: show a local notification that navigates to order 123 on tap
          NotificationService.instance.showOrderNotification(
            orderId: 123,
            title: 'Narudžba #123',
            body: 'Dodirnite za detalje narudžbe',
          );
        },
        label: const Text('Test notifikacija'),
        icon: const Icon(Icons.notifications_active_outlined),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (int i) => setState(() => _index = i),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Torbe'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Kaiševi'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Korpa'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

