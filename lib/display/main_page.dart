import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/display/navigation_index_cubit.dart';

import 'home_app_bar.dart';
import 'listings_widget.dart';
import 'messages_widget.dart';

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

  @override
  Widget build(BuildContext context) {
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
            ListingsWidget(widget.title),
            MessagesWidget(widget.title),
            Center(child: Text('more'))
          ],
        )
      ),
      bottomNavigationBar: HomeAppBar(),
    );
  }
}
