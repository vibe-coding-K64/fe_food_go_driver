import 'package:flutter/material.dart';
import 'driver_bottom_nav.dart';

class NavigationShell extends StatefulWidget {
  final List<Widget> tabs;
  final int initialIndex;

  const NavigationShell({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.tabs,
      ),
      bottomNavigationBar: DriverBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
