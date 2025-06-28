import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mypath/widgets/custom_bottom_nav_bar.dart';
import 'package:mypath/screens/home_tab_navigator.dart'; // Import the new HomeTabNavigator
import 'package:mypath/screens/history_screen.dart'; // Import the actual HistoryScreen

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; // Current selected tab index

  // GlobalKeys for each tab's NavigatorState
  final GlobalKey<NavigatorState> _homeTabNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileTabNavigatorKey = GlobalKey<NavigatorState>();
  // HistoryScreen does not need a nested NavigatorKey if it's the root of its tab
  // and doesn't push internal routes that need separate navigation history.

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeTabNavigator(navigatorKey: _homeTabNavigatorKey),
      _ProfileScreenPlaceholder(navigatorKey: _profileTabNavigatorKey), // Pass key to Profile placeholder
      const HistoryScreen(), // Use the actual HistoryScreen here
    ];
  }

  @override
  void dispose() {
    // No PageController to dispose of with IndexedStack
    // Disposing of GlobalKey's currentState is generally not recommended unless
    // you are managing the Navigator's lifecycle very specifically.
    // The Navigator itself typically handles its state.
    super.dispose();
  }

  void _onItemTapped(int index) {
    // When using IndexedStack, simply change the selected index
    // No need for a PageController or jumpToPage
    setState(() {
      _selectedIndex = index;
    });
  }

  // Handle system back button presses for nested navigators
  Future<bool> _onWillPop() async {
    // Determine the current tab's navigator key based on _selectedIndex
    GlobalKey<NavigatorState>? currentNavigatorKey;
    switch (_selectedIndex) {
      case 0: // Home tab
        currentNavigatorKey = _homeTabNavigatorKey;
        break;
      case 1: // Profile tab
        currentNavigatorKey = _profileTabNavigatorKey;
        break;
      case 2: // History tab (assuming it's a leaf screen without a nested navigator to pop from)
        // If the HistoryScreen had internal routes, you would give it a navigatorKey
        // and check currentNavigatorKey.currentState!.canPop() here.
        // For now, if on History tab, we allow the main wrapper to pop (go to home or exit app).
        return true;
      default:
        return true; // Should not happen, allow default pop
    }

    // If the current tab has a nested navigator and it can pop, pop from it
    if (currentNavigatorKey != null && currentNavigatorKey.currentState != null && currentNavigatorKey.currentState!.canPop()) {
      currentNavigatorKey.currentState!.pop();
      return false; // Prevent app from exiting, handled internally by tab
    }

    // If already on the Home tab (index 0) and its navigator is at its root,
    // then allow the main navigator to pop (potentially exiting the app or going to login).
    if (_selectedIndex == 0) {
      return true; // Allow the main Navigator to pop
    }

    // If not on the Home tab and its navigator is at its root, switch to the Home tab
    setState(() {
      _selectedIndex = 0;
    });
    // No pageController.jumpToPage needed for IndexedStack
    return false; // Prevent app from exiting, handled by switching tab
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents default pop behavior, we handle it manually
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return; // If a pop gesture was already handled by the system, do nothing
        }
        final bool shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // If shouldPop is true and the widget is still mounted,
          // it means we want to pop the MainWrapper itself.
          // This will go back to the previous route (likely login) or exit the app.
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Center(
            child: Image.asset(
              'assets/images/logo.png', // Ensure this path is correct
              height: 40,
              width: 120,
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  // Ensure replacement to /login is on the root navigator
                  // This is crucial to clear the stack and prevent black screens.
                  Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
        body: IndexedStack( // Changed from PageView to IndexedStack
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}

// --- Updated Placeholder for Profile Screen to accept a NavigatorKey ---
class _ProfileScreenPlaceholder extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const _ProfileScreenPlaceholder({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey, // Use the provided key
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Profile Screen Content',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile details will go here!')),
                    );
                  },
                  child: const Text('View Profile Details'),
                ),
              ],
            ),
          ),
        );
      },
      initialRoute: '/', // Define initial route for this tab
    );
  }
}
