import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'navigation_index_cubit.dart';

/// App bar at the bottom; varies by iOS or material
class HomeAppBar extends StatelessWidget {
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationIndexCubit, int>(builder: (context, index) {
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
                icon: Icon(CupertinoIcons.conversation_bubble),
                label: 'Messages'),

            /// TODO implement more dialog with login and feedback
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.ellipsis_circle), label: 'More'),
          ],
          currentIndex: index,
          onTap: (index) =>
              BlocProvider.of<NavigationIndexCubit>(context).setIndex(index),
          backgroundColor: Theme.of(context).colorScheme.background,
          activeColor: Theme.of(context).colorScheme.primaryVariant,
          inactiveColor: Theme.of(context).colorScheme.onBackground,
        );
      } else {
        w = BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Posts'),
            BottomNavigationBarItem(
                icon: Icon(Icons.message), label: 'Messages'),
          ],
          currentIndex: index,
          onTap: (index) =>
              BlocProvider.of<NavigationIndexCubit>(context).setIndex(index),
          // backgroundColor: Theme.of( context ).colorScheme.primary,
        );
      }
      return w;
    });
  }
}
