import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/display/navigation_index_cubit.dart';

import 'listings_widget.dart';
import 'messages_widget.dart';
import 'dart:io';

final GlobalKey<NavigatorState> firstTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> secondTabNavKey = GlobalKey<NavigatorState>();

/// Shows a list of postings and messages from Reddit.
class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

/// TODO Move login from FAB into app bar and show login state
class _MainPageState extends State<MainPage> {
  final Logger logger = Logger();
  int _selectedTab;

  Widget listingsWidget, messagesWidget;

  @override
  void initState() {
    super.initState();
    _selectedTab = 0;
  }

  @override
  void dispose() {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit?.dispose();
    super.dispose();
  }

  // TODO add FAB if MessagesWidget is selected and user is logged-in
  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          onTap: (index) {
            if (_selectedTab == index) {
              switch (index) {
                case 0:
                  firstTabNavKey.currentState.popUntil((r) => r.isFirst);
                  break;
                case 1:
                  secondTabNavKey.currentState.popUntil((r) => r.isFirst);
                  break;
                default:
                  logger.e('Unknown tab index $index selected');
              }
            }
            _selectedTab = index;
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet),
              label: 'Posts',
            ),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.conversation_bubble),
                label: 'Messages'),
          ],
          backgroundColor: Theme.of(context).colorScheme.background,
          activeColor: Theme.of(context).colorScheme.primaryVariant,
          inactiveColor: Theme.of(context).colorScheme.onBackground,
        ),
        tabBuilder: (context, index) {
          var page = (index == 0) ? ListingsWidget() : MessagesWidget();
          var key = (index == 0) ? firstTabNavKey : secondTabNavKey;
          return CupertinoTabView(
            navigatorKey: key,
            builder: (context) {
              return CupertinoPageScaffold(
                child: page,
              );
            },
          );
        },
      );
    } else {
      return Scaffold(
        body: MultiBlocListener(
            listeners: [
              BlocListener<NavigationIndexCubit, int>(
                  listener: (context, index) =>
                      setState(() => _selectedTab = index))
            ],
            child: IndexedStack(
              index: _selectedTab,
              children: [
                ListingsWidget(),
                MessagesWidget(),
                const Center(child: Text('more'))
              ],
            )),
        bottomNavigationBar:
            BlocBuilder<NavigationIndexCubit, int>(builder: (context, index) {
          return BottomNavigationBar(
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
        }),
      );
    }
  }
}
