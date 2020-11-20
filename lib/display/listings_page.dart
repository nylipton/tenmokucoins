import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/subreddit_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

import 'DateTimeFormatter.dart';

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
        // appBar: AppBar(
        //   elevation: 1.0,
        //   title: Text(widget.title,),
        //   textTheme: GoogleFonts.poppinsTextTheme( Theme.of(context).textTheme ),
        // ),
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
                  w = Center(child: CircularProgressIndicator());
                else
                  w = Expanded(child: _getMainList(context));
                return w;
              }),
            ])),
        floatingActionButton: BlocBuilder<RedditClientCubit, RedditWrapper>(
            builder: (_, redditWrapper) {
          Widget w;
          if (redditWrapper != null && redditWrapper.isAuthenticated())
            w = Container();
          else
            w = FloatingActionButton(
              onPressed: () => _authenticate(context),
              tooltip: 'Authenticate to Reddit',
              child: _isLoading ? Icon(Icons.stream) : Icon(Icons.login),
            );
          return w;
        }));
  }

  void _authenticate(BuildContext context) {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit.authenticate();
  }

  /// The main body of this page; this is the list that loads submissions (i.e
  /// posts or articles)
  Widget _getMainList(BuildContext context) {
    Widget w = BlocBuilder<SubredditBloc, SubredditListState>(
        builder: (_, SubredditListState state) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            elevation: 1.0,
            title: Text(
              widget.title,
            ),
            textTheme:
                GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
            floating: true,
            // expandedHeight: 150,
            // flexibleSpace: Image.network("https://upload.wikimedia.org/wikipedia/commons/f/fa/NNC-US-1907-G%2420-Saint_Gaudens_%28Roman%2C_ultra_high_relief%2C_wire_edge%29.jpg"),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if ((state.submissions.length - _nextPageThreshold) == index)
                  BlocProvider.of<SubredditBloc>(context)
                      .add(SubredditListLoadSubmissions(numberToLoad: 10));
                return createListTile(state.submissions, index);
              },
              childCount: state.submissions.length + (_isLoading ? 1 : 0),
            ),
          ),
        ],
      );
    });

    // RefreshIndicator is so the list will clear and refresh when pulled down
    w = RefreshIndicator(
        onRefresh: () => Future<void>(() =>
            BlocProvider.of<SubredditBloc>(context)
                .add(SubredditListClearEvent())),
        child: w);

    return w;
  }

  /// this is the main list tile that will go in the list
  Widget createListTile(List<SubmissionItem> contentList, int index) {
    Widget w, leading, trailing;
    String title, subtitle;

    if (contentList.length == 0 || index == contentList.length) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      ));
    } else {
      Submission s = contentList[index].submission;
      title =
          '${contentList[index].getTitle().replaceAll(RegExp("\\[[Ww][Tt][bBsStT]\\][\s\\\/\,]*"), "").replaceAll(RegExp("^\\s*"),"")}';
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
}
