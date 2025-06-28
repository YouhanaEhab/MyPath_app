import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<BottomNavigationBarItem> items; // Accept a list of items

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items, // Make the list required
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: items, // Use the provided list of items
      currentIndex: selectedIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: onItemTapped,
      backgroundColor: Colors.white,
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
    );
  }
}
