import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/subreddit_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

import 'DateTimeFormatter.dart';
import 'home_app_bar.dart';

/// Shows a list of postings from Reddit.
class ListingsPage extends StatefulWidget {
  ListingsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ListingsPageState createState() => _ListingsPageState();
}

/// TODO Move login from FAB into app bar and show login state
/// TODO Restyle list tile and move it into a separate class+file
class _ListingsPageState extends State<ListingsPage> {
  /// if this is currently loading new data
  bool _isLoading;

  var logger = Logger();

  /// When the user views the item [_nextPageThreshhold] away from the bottom,
  /// more items are requested from the server
  static const int _nextPageThreshold = 5;

  static const String accounts = 'Accounts';

  static const String feedback = 'Feedback';

  /// Overflow menu options
  static const List<String> overflowMenu = [accounts, feedback];

  /// tags are used as filters for the list (or highlights, depending on implementation)
  List<String> tags;

  @override
  void initState() {
    super.initState();
    _isLoading = false;

    /// TODO store tags locally on the device
    tags = [];
    BlocProvider.of<SubredditBloc>(context).listen((state) {
      setState(() {
        _isLoading = (state is SubredditListLoadingState);
      });
    });
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
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            BlocBuilder<RedditClientCubit, RedditWrapper>(
                builder: (context, redditWrapper) {
              logger.v('BlocBuilder called with $redditWrapper');
              Widget w;
              if (redditWrapper == null || redditWrapper.reddit == null)
                w = Center(
                    child: (Platform.isIOS)
                        ? CupertinoActivityIndicator()
                        : CircularProgressIndicator());
              else
                w = Expanded(child: _getMainList(context));
              return w;
            }),
          ])),
      bottomNavigationBar: HomeAppBar(),
      // floatingActionButton: BlocBuilder<RedditClientCubit, RedditWrapper>(
      //     builder: (_, redditWrapper) {
      //   Widget w;
      //   if (redditWrapper != null && redditWrapper.isAuthenticated())
      //     w = Container();
      //   else
      //     w = FloatingActionButton(
      //       onPressed: () => _authenticate(context),
      //       tooltip: 'Authenticate to Reddit',
      //       child: _isLoading ? Icon(Icons.stream) : Icon(Icons.login),
      //     );
      //   return w;
      // }
      // )
    );
  }

  /// The main body of this page; this is the list that loads submissions (i.e
  /// posts or articles)
  Widget _getMainList(BuildContext context) {
    Widget w = BlocBuilder<SubredditBloc, SubredditListState>(
        builder: (_, SubredditListState state) {
      List<SubmissionWrapper> listWrappers = state.submissions
          .map((s) => SubmissionWrapper(item: s, tags: tags))
          .toList(growable: false);
      // listWrappers.sort((a, b) {
      //   int aMatches = a.matchingTags.length;
      //   int bMatches = b.matchingTags.length;
      //   if (aMatches == bMatches)
      //     return a.item.getTimestamp().compareTo(b.item.getTimestamp());
      //   else
      //     return a.matchingTags.length.compareTo(b.matchingTags.length);
      // });

      List<Widget> sliverlist = [];

      Widget appBar;
      if (Platform.isIOS) {
        /// TODO handle bug where tile catches onTap instead of app bar's action
        appBar = CupertinoSliverNavigationBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            largeTitle: Text(widget.title),
            trailing: Material(
              color: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: Icon(CupertinoIcons.exclamationmark_shield,
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
          ),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          pinned: false,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Interests',
              onPressed: _highlight,
            ),
            PopupMenuButton<String>(
              onSelected: _choiceAction,
              itemBuilder: (_) {
                return overflowMenu.map((String choice) {
                  return PopupMenuItem<String>(
                      value: choice, child: Text(choice));
                }).toList();
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

  /// this is the main list tile that will go in the list
  Widget createListTile(List<SubmissionWrapper> contentList, int index) {
    Widget w, leading, trailing;

    if (contentList.length == 0) {
      return Container();
    } else if (index == contentList.length) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(8),
        child: (Platform.isIOS)
            ? CupertinoActivityIndicator()
            : CircularProgressIndicator(),
      ));
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
            padding: EdgeInsets.fromLTRB(3,0,3,0),
            shape: BadgeShape.square,
            badgeColor: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(15.0),
            badgeContent: Text(tag, style: Theme.of( context ).textTheme.bodyText1),
            elevation: 0.0,
          ),
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic);
    }).toList();

    w = ListTile(
        leading: leading,
        title: Text.rich(
          TextSpan(
              text: contentList[index].title+' ',
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

  /// used to launch the browser
  _launch(Uri shortlink) {
    logger.d(shortlink);
    launch(shortlink.toString());
  }

  /// Launches the filter dialog to get the tags
  _highlight() async {
    logger.d('Filter main submissions list selected');
    final result =
        await Navigator.pushNamed(context, '/filter', arguments: tags);
    logger.d('Filter dialog returned $result');
    if (result != null) {
      setState(() {
        tags = result;
      });
      // TODO Find out why Snackbar can't find a scaffold!
      // ScaffoldMessenger.of( context ).showSnackBar( const SnackBar(content: Text( 'New filters set'),)) ;
    }
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

/// Holds a [SubmissionItem] and provides display facilities such as the
/// title to be shown and whether it matches a filter highlight list
class SubmissionWrapper {
  static Logger logger = Logger();
  final SubmissionItem item;
  bool _hasMatch = false;
  String _title;
  String _avatarString;

  String _subtitle;

  List<String> _matchingTags = [];

  SubmissionWrapper({this.item, List<String> tags = const []})
      : assert(item != null) {
    tags.forEach((tag) {
      RegExp regex = RegExp(tag, caseSensitive: false) ;
      if (regex.firstMatch(item.getTitle()) !=null || (item.submission.isSelf && regex.firstMatch(item.submission.selftext) != null )) {
        _matchingTags.add(tag);
        _hasMatch = true;
      }
    });

    StringBuffer sb = StringBuffer();
    _matchingTags.forEach((t) => sb.write(t + ' '));
    sb.write(item
        .getTitle()
        .replaceAll(RegExp("\\[[Ww][Tt][bBsStT]\\][\s\\\/\,]*"), "")
        .replaceAll(RegExp("^\\s*"), "")
        .replaceAll(RegExp("&amp;"), "&"));
    _title = sb.toString();

    _subtitle =
        '${item.getSubredditTitle()}: ${DateTimeFormatter.format(item.getTimestamp())}';

    Set<PostType> postTypes = item.getPostTypes();
    _avatarString = (postTypes.length == 0)
        ? "?"
        : postTypes
            .map((p) => p.toShortString())
            .reduce((value, element) => value + '/' + element);
  }

  /// The display title
  String get title => _title;

  /// Subreddit and posting time
  String get subtitle => _subtitle;

  /// B, S or T depending on the post type (i.e. buy, sell or trade)
  String get avatarString => _avatarString;

  /// Did any of the tags match?
  bool get hasMatch => _hasMatch;

  /// Which tags matched?
  List<String> get matchingTags => _matchingTags;
}
