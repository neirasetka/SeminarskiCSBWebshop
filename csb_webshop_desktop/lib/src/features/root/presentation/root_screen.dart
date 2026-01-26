import 'package:flutter/material.dart';

import '../../bags/presentation/bags_list_screen.dart';
import '../../belts/presentation/belts_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../orders/presentation/cart_screen.dart';
// import '../../../core/notification_service.dart';
import 'package:go_router/go_router.dart';
import '../../giveaways/presentation/giveaways_list_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.title, this.initialIndex = 0});

  final String title;
  final int initialIndex;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const BagsListScreen(),
      const BeltsListScreen(),
      const CartScreen(),
      ProfileScreen(title: widget.title),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Kaiševi',
            icon: const Icon(Icons.checkroom_outlined),
            onPressed: () => context.go('/belts'),
          ),
          IconButton(
            tooltip: 'Izvještaji',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.go('/reports'),
          ),
          IconButton(
            tooltip: 'Checkout demo',
            icon: const Icon(Icons.payment_outlined),
            onPressed: () => context.go('/checkout'),
          ),
          IconButton(
            tooltip: 'Lookbook',
            icon: const Icon(Icons.grid_view_outlined),
            onPressed: () => context.go('/lookbook'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const GiveawaysListScreen()),
          );
        },
        label: const Text('Giveawayi'),
        icon: const Icon(Icons.celebration_outlined),
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

