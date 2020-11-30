import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/display/navigation_index_cubit.dart';

import 'home_app_bar.dart';
import 'listings_widget.dart';

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
  int _selectedTab  ;
  RedditWrapper _redditWrapper ;


  @override
  void initState() {
    _selectedTab = 0 ;
    _redditWrapper = null ;
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
      body: MultiBlocListener (
        listeners: [
        BlocListener<RedditClientCubit, RedditWrapper>(
          listener: (context, redditWrapper) => setState( ()=> _redditWrapper = redditWrapper)
      ),
      BlocListener<NavigationIndexCubit, int>(
        listener: (context, index) => setState( ()=>_selectedTab = index)
      )
      ],
      child: _mainWidget(),
    ),
      bottomNavigationBar: HomeAppBar(),
    ) ;
  }

  Widget _mainWidget( ) {
    Widget main;
    if (_selectedTab == 0) {
      main = ListingsWidget(widget.title);
    }
    else if (_selectedTab == 1) {
      main = Center(child: Text('messages'));
    }
    else if (_selectedTab == 2) {
      main = Center(child: Text('more'));
    }
    else {
      main = Container( ) ;
      logger.e('Navigation index set to unknown tab: $_selectedTab');
    }
    return Stack(
        fit: StackFit.expand,
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          (_redditWrapper == null || _redditWrapper.reddit == null)
              ? Align( alignment: Alignment.center,child: PlatformCircularProgressIndicator() )
              : Container(),
          main,
        ]);
  }
}
