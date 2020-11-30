import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/subreddit_bloc.dart';
import 'package:tenmoku_coins/display/submission_tile.dart';
import 'package:tenmoku_coins/display/submission_wrapper.dart';

/// The main component of the page that shows listings (i.e. submissions).
class ListingsWidget extends StatefulWidget {
  final String title;

  ListingsWidget(this.title);

  @override
  State<StatefulWidget> createState() => ListingsWidgetState();
}

class ListingsWidgetState extends State<ListingsWidget> {
  /// tags are used as filters for the list (or highlights, depending on implementation)
  List<String> _tags = [];
  final Logger logger = Logger();

  /// When the user views the item [_nextPageThreshold] away from the bottom,
  /// more items are requested from the server
  static const int _nextPageThreshold = 5;

  static const String accounts = 'Accounts';

  static const String about = 'About';

  /// if this is currently loading new data
  bool _isLoading;

  /// Overflow menu options
  static const List<String> overflowMenu = [accounts, about];

  /// Key used in shared_preferences to store the user's tags
  static const tagsKey = 'user_tags';

  /// This will load up [SharedPreferences] when ready.
  final Future<SharedPreferences> _futureprefs =
      SharedPreferences.getInstance();

  /// Used to save tags locally on the device
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();

    _futureprefs.then((prefs) => _prefs = prefs).then((_) {
      setState(() {
        _tags = _prefs.getStringList('user_tags') ?? [];
        logger.d('Loaded tags from memory: $_tags');
      });
    });

    _isLoading = false;

    BlocProvider.of<SubredditBloc>(context).listen((state) {
      setState(() {
        _isLoading = (state is SubredditListLoadingState);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget w = BlocBuilder<SubredditBloc, SubredditListState>(
        builder: (_, SubredditListState state) {
      List<SubmissionWrapper> listWrappers = state.submissions
          .map((s) => SubmissionWrapper(item: s, tags: _tags))
          .toList(growable: false);

      List<Widget> sliverlist = [];

      Widget appBar;
      if (Platform.isIOS) {
        /// TODO Handle bug where tile catches onTap instead of app bar's action
        appBar = CupertinoSliverNavigationBar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .primary, // TODO See if this can be removed on iOS
            largeTitle: Text(widget.title),
            trailing: Material(
              color: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: Icon(CupertinoIcons.heart_circle,
                    color: Theme.of(context).colorScheme.onPrimary),
                tooltip: 'Interests',
                onPressed: _highlight,
              ),
            ));
      } else {
        appBar = SliverAppBar(
          elevation: 1.0,
          title: Text(
            widget.title,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          pinned: false,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.rule),
              tooltip: 'Interests',
              onPressed: _highlight,
            ),
            PopupMenuButton<String>(
              onSelected: _overflowMenuAction,
              itemBuilder: (_) {
                var redditWrapper =
                    BlocProvider.of<RedditClientCubit>(context).state;
                Widget accountField;
                accountField = (redditWrapper.isAuthenticated())
                    ? FutureBuilder(
                        future: redditWrapper.getUsername(),
                        initialData: 'Reddit account: loading',
                        builder: (_, AsyncSnapshot<String> data) {
                          return data.hasData
                              ? Text(data.data)
                              : Text('Loading Reddit account');
                        })
                    : Text('Login to Reddit');
                return <PopupMenuItem<String>>[
                  PopupMenuItem<String>(
                    value: overflowMenu[0],
                    child: accountField,
                    enabled: !redditWrapper.isAuthenticated(),
                  ),
                  PopupMenuItem<String>(
                      value: overflowMenu[1], child: Text(overflowMenu[1]))
                ];
              },
            )
          ],
        );
      }
      sliverlist.add(appBar);

      if (Platform.isIOS) {
        sliverlist.add(CupertinoSliverRefreshControl(
          onRefresh: () => Future<void>(() =>
              BlocProvider.of<SubredditBloc>(context)
                  .add(SubredditListClearEvent())),
        ));
      }
      // this is the actual list of submissions
      sliverlist.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // if we're near the end, request more submissions from Reddit
            if ((listWrappers.length - _nextPageThreshold) == index) {
              BlocProvider.of<SubredditBloc>(context)
                  .add(SubredditListLoadSubmissions(numberToLoad: 10));
            }
            // generate the tile for the submission
            return createListTile(listWrappers, index);
          },
          childCount: listWrappers.length + (_isLoading ? 1 : 0),
        ),
      ));

      return CustomScrollView(
        slivers: sliverlist,
        shrinkWrap: true,
      );
    });

    // RefreshIndicator is so the list will clear and refresh when pulled down
    if (!Platform.isIOS) {
      w = RefreshIndicator(
          onRefresh: () => Future<void>(() =>
              BlocProvider.of<SubredditBloc>(context)
                  .add(SubredditListClearEvent())),
          child: w);
    }
    return w;
  }

  /// Launches the interests dialog to get the tags
  void _highlight() async {
    logger.d('Filter main submissions list selected');
    final result =
        await Navigator.pushNamed(context, '/filter', arguments: _tags);
    logger.d('Filter dialog returned $result');
    if (result != null) {
      setState(() {
        _tags = result;
      });

      await _prefs.setStringList(tagsKey, result);
      logger.d('Saved updated tags: $_tags');
    }
  }

  /// this is the main list tile that will go in the list
  Widget createListTile(List<SubmissionWrapper> contentList, int index) {
    if (contentList.isEmpty) {
      return Container();
    } else if (index == contentList.length) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: PlatformCircularProgressIndicator()));
    } else {
      return SubmissionTile(contentList[index]);
    }
  }

  /// For the overflow menu choice
  void _overflowMenuAction(String choice) {
    if (choice == accounts) {
      logger.d('User chose to edit accounts');
      _authenticate(context);
    } else {
      logger.d('Showing about dialog');
      showAboutDialog( context: context, applicationLegalese: "Copyright 2020, Tenmoku LLC") ;
    }
  }

  void _authenticate(BuildContext context) {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit.authenticate();
  }
}
