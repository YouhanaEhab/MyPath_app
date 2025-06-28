import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mypath/widgets/custom_bottom_nav_bar.dart';

class MainWrapper extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapper({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  bool _isAdmin = false;
  bool _isCheckingAdminStatus = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  @override
  void didUpdateWidget(covariant MainWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell != oldWidget.navigationShell) {
      _checkAdminStatus();
    }
  }

  Future<void> _checkAdminStatus() async {
    setState(() => _isCheckingAdminStatus = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() { _isAdmin = false; _isCheckingAdminStatus = false; });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists && (userDoc.data()?['isAdmin'] == true)) {
        setState(() => _isAdmin = true);
      } else {
         if (mounted) setState(() => _isAdmin = false);
      }
    } catch (e) {
      print("Error checking admin status: $e");
      if (mounted) setState(() => _isAdmin = false);
    } finally {
      if(mounted) setState(() => _isCheckingAdminStatus = false);
    }
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> navBarItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
    ];

    if (_isAdmin) {
      navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }
    
    final int selectedIndex = widget.navigationShell.currentIndex;

    return PopScope(
      canPop: false, // We will handle the pop action manually
      onPopInvoked: (didPop) {
        if(didPop) return;

        // If on any tab other than the first ('Home'), go to the 'Home' tab.
        if (widget.navigationShell.currentIndex != 0) {
          _onItemTapped(0);
        } else {
          // If on the 'Home' tab, go to the main welcome screen.
          context.go('/main');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: selectedIndex == 0 // Only show back button on the Home tab
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: () => context.go('/main'),
              )
            : null,
          title: Image.asset('assets/images/logo.png', height: 35),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black54),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
        body: _isCheckingAdminStatus 
            ? const Center(child: CircularProgressIndicator()) 
            : widget.navigationShell,
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: selectedIndex,
          onItemTapped: _onItemTapped,
          items: navBarItems,
        ),
      ),
    );
  }
}
