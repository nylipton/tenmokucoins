import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeAppBarState();
  }
}

// TODO implement CupertinoTabBar for iOS
class _HomeAppBarState extends State<HomeAppBar> {
  /// The selected home navigation item
  int _selectedIndex;

  @override
  void initState() {
    _selectedIndex = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    if (Platform.isIOS) {
      w = CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Posts',
          ),
          /// TODO implement messages
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.conversation_bubble), label: 'Messages'),
          /// TODO implement more dialog with login and feedback
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.ellipsis_circle), label: 'More'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.background,
        activeColor: Theme.of(context).colorScheme.primaryVariant,
        inactiveColor: Theme.of(context).colorScheme.onBackground,
      );
    } else {
      w = BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Posts'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          // backgroundColor: Theme.of( context ).colorScheme.primary,
      );
    }

    return w;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // if( inde
  }
}
