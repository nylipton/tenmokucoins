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
/// TODO Restyle list tile and move it into a separate class+file
class _MainPageState extends State<MainPage> {
  final Logger logger = Logger();

  /// tags are used as filters for the list (or highlights, depending on implementation)
  List<String> _tags = [];

  @override
  void dispose() {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<RedditClientCubit, RedditWrapper>(
          builder: (context, redditWrapper) {
        logger.v('BlocBuilder called with $redditWrapper');

        return BlocBuilder<NavigationIndexCubit, int>(
            builder: (context, index) {
          logger.v('Main page\'s index set to $index');

          Widget main;
          if (index == 0)
            main = ListingsWidget(widget.title, _tags);
          else if (index == 1)
            main = Center(child: Text('messages'));
          else if (index == 2)
            main = Center(child: Text('more'));
          else
            logger.e('Navigation index set to $index');
          return Stack(
              fit: StackFit.expand,
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                (redditWrapper == null || redditWrapper.reddit == null)
                    ? Align( alignment: Alignment.center,child: PlatformCircularProgressIndicator() )
                    : Container(),
                main,
              ]);
        });
      }),
      bottomNavigationBar: HomeAppBar(),
    );
  }
}
