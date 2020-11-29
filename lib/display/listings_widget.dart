
import 'dart:io';

import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/subreddit_bloc.dart';
import 'package:tenmoku_coins/display/submission_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

/// The main component of this page when showing the listings.
/// This is the list that loads submissions (i.e posts or articles).
class ListingsWidget extends StatefulWidget {

  final String title ;
  final List<String> _tags ;
  ListingsWidget(this.title, this._tags);

  @override
  State<StatefulWidget> createState() => ListingsWidgetState(_tags) ;
}

class ListingsWidgetState extends State<ListingsWidget> {
  /// tags are used as filters for the list (or highlights, depending on implementation)
  List<String> _tags = [];
  final Logger logger = Logger();
  /// When the user views the item [_nextPageThreshhold] away from the bottom,
  /// more items are requested from the server
  static const int _nextPageThreshold = 5;

  static const String accounts = 'Accounts';

  static const String feedback = 'Feedback';

  /// if this is currently loading new data
  bool _isLoading;

  /// Overflow menu options
  static const List<String> overflowMenu = [accounts, feedback];
  ListingsWidgetState(this._tags);


  /// key used in shared_preferences
  static const tagsKey = 'user_tags';

  Future<SharedPreferences> _futureprefs = SharedPreferences.getInstance();
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
            /// TODO handle bug where tile catches onTap instead of app bar's action
            appBar = CupertinoSliverNavigationBar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary, // TODO see if this can be removed on iOS
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
                  onSelected: _choiceAction,
                  itemBuilder: (_) {
                    RedditWrapper redditWrapper =
                        BlocProvider.of<RedditClientCubit>(context).state;
                    Widget accountField;
                    if (redditWrapper.isAuthenticated())
                      accountField = FutureBuilder(
                          future: redditWrapper.getUsername(),
                          initialData: 'Reddit account: loading',
                          builder: (_, AsyncSnapshot<String> data) {
                            return data.hasData
                                ? Text(data.data)
                                : Text("Loading Reddit account");
                          });
                    else
                      accountField = Text("Login to Reddit");
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
                if ((listWrappers.length - _nextPageThreshold) == index)
                  BlocProvider.of<SubredditBloc>(context)
                      .add(SubredditListLoadSubmissions(numberToLoad: 10));
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


  /// used to launch the browser
  _launch(Uri shortlink) {
    logger.d(shortlink);
    launch(shortlink.toString());
  }

  /// Launches the filter dialog to get the tags
  _highlight() async {
    logger.d('Filter main submissions list selected');
    final result =
    await Navigator.pushNamed(context, '/filter', arguments: _tags);
    logger.d('Filter dialog returned $result');
    if (result != null) {
      setState(() {
        _tags = result;
      });

      _prefs
          .setStringList(tagsKey, result)
          .then((t) => logger.d('Saved updated tags: $_tags'));
      // TODO Find out why Snackbar can't find a scaffold!
      // ScaffoldMessenger.of( context ).showSnackBar( const SnackBar(content: Text( 'New filters set'),)) ;
    }
  }


  /// this is the main list tile that will go in the list
  Widget createListTile(List<SubmissionWrapper> contentList, int index) {
    Widget w, leading, trailing;

    if (contentList.length == 0) {
      return Container();
    } else if (index == contentList.length) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: PlatformCircularProgressIndicator()));
    } else {
      Color avatarBackgroundColor = contentList[index].hasMatch
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.primaryVariant;
      Color avatarForegroundColor = contentList[index].hasMatch
          ? Theme.of(context).colorScheme.onSecondary
          : Theme.of(context).colorScheme.onPrimary;

      leading = CircleAvatar(
        child: Text(contentList[index].avatarString,
            style: TextStyle(color: avatarForegroundColor)),
        backgroundColor: avatarBackgroundColor,
      );
      trailing = GestureDetector(
          behavior: HitTestBehavior.opaque,
          // TODO figure out why this is taking over taps even if the appbar is over it
          onTap: () => _launch(contentList[index].item.submission.url),
          child: Icon(
            Icons.keyboard_arrow_right,
          ));
    }

    List<WidgetSpan> tagWidgets = contentList[index].matchingTags.map((tag) {
      return WidgetSpan(
          child: Badge(
            padding: EdgeInsets.fromLTRB(3, 0, 3, 0),
            shape: BadgeShape.square,
            badgeColor: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(15.0),
            badgeContent:
            Text(tag, style: Theme.of(context).textTheme.bodyText1),
            elevation: 0.0,
          ),
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic);
    }).toList();

    w = ListTile(
        leading: leading,
        title: Text.rich(
          TextSpan(
              text: contentList[index].title + ' ',
              children: tagWidgets.toList()),
        ),
        subtitle: Text(contentList[index].subtitle),
        dense: true,
        trailing: trailing);

    /// the column is to include a divider
    w = Column(
      children: [
        w,
        Divider(
          height: 0,
        )
      ],
    );

    return w;
  }

  /// For the overflow menu choice
  void _choiceAction(String choice) {
    if (choice == accounts) {
      logger.d('User chose to edit accounts');
      _authenticate(context);
    } else {
      logger.d('User chose to give feedback');
    }
  }

  void _authenticate(BuildContext context) {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit.authenticate();
  }
}
