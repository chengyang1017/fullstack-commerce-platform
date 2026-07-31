import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'cart_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [HomePage(), CartPage()];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changePage,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: '主頁'),
          NavigationDestination(icon: Icon(Icons.shop), label: '購物車'),
        ],
      ),
    );
  }
}
