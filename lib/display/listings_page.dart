import 'package:draw/draw.dart';
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

  @override
  void initState() {
    super.initState();
    _isLoading = false;
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
      List<Widget> sliverlist = [];

      Widget appBar;
      if (Platform.isIOS) {
        appBar = CupertinoSliverNavigationBar(
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .primary,
            largeTitle: Text(widget.title),
            trailing: Material(
              color: Theme
                  .of(context)
                  .colorScheme
                  .primary,
              child: IconButton(
                icon: Icon(CupertinoIcons.slider_horizontal_3,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onPrimary),
                tooltip: 'Filter posts',
                onPressed: _filter,
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
              tooltip: 'Filter posts',
              onPressed: _filter,
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
      sliverlist.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if ((state.submissions.length - _nextPageThreshold) == index)
              BlocProvider.of<SubredditBloc>(context)
                  .add(SubredditListLoadSubmissions(numberToLoad: 10));
            return createListTile(state.submissions, index);
          },
          childCount: state.submissions.length + (_isLoading ? 1 : 0),
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
  Widget createListTile(List<SubmissionItem> contentList, int index) {
    Widget w, leading, trailing;
    String title, subtitle;

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
      Submission s = contentList[index].submission;
      title =
          '${contentList[index].getTitle().replaceAll(RegExp("\\[[Ww][Tt][bBsStT]\\][\s\\\/\,]*"), "").replaceAll(RegExp("^\\s*"), "")}';
      subtitle =
          '$index: ${contentList[index].getSubredditTitle()}: ${DateTimeFormatter.format(contentList[index].getTimestamp())}';
      Set<PostType> postTypes = contentList[index].getPostTypes();
      String avatar = (postTypes.length == 0)
          ? "?"
          : postTypes
              .map((p) => p.toShortString())
              .reduce((value, element) => value + '/' + element);
      Color avatarBackgroundColor =
          Theme.of(context).colorScheme.primaryVariant; //Colors.grey;
      Color avatarForegroundColor =
          Theme.of(context).colorScheme.onPrimary; //Colors.white;

      leading = CircleAvatar(
        child: Text(avatar, style: TextStyle(color: avatarForegroundColor)),
        backgroundColor: avatarBackgroundColor,
      );
      trailing = InkWell(
          onTap: () => _launch(s.url),
          child: Icon(
            Icons.keyboard_arrow_right,
          ));
    }

    w = ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Text(subtitle),
        dense: true,
        trailing: trailing);
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

  void _filter() {
    logger.d('Filter main submissions list selected');
    Navigator.pushNamed( context, '/filter' ) ;
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
