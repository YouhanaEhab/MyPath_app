import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.green, // MyPath green
      unselectedItemColor: Colors.grey,
      onTap: onItemTapped,
      backgroundColor: Colors.white,
      elevation: 8.0, // Add some shadow
      type: BottomNavigationBarType.fixed, // Ensures labels are always shown
    );
  }
}
