import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tenmoku_coins/display/DateTimeFormatter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bloc/reddit_client_cubit.dart';
import 'bloc/subreddit_cubit.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tenmoku Coins',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: BlocProvider(
        lazy: false,
        create: (_) => RedditClientCubit(),
        child: MyHomePage(title: 'Tenmoku Coins'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// todo Move login from FAB into app bar and show login state
/// todo Restyle list tile and move it into a separate class+file
class _MyHomePageState extends State<MyHomePage> {
  @override
  void dispose() {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            BlocBuilder<RedditClientCubit, RedditWrapper>(
                builder: (_, redditWrapper) {
              // print('BlocBuilder called with $redditWrapper');
              Widget w;
              if (redditWrapper.reddit == null)
                w = Center(child: CircularProgressIndicator());
              else
                w = Expanded(
                    child: _getMainList(redditWrapper.getSubredditsCubit()));

              return w;
            }),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<RedditClientCubit, RedditWrapper>(
          builder: (_, redditWrapper) {
        Widget w;
        if (redditWrapper != null && redditWrapper.isAuthenticated())
          w = Container();
        else
          w = FloatingActionButton(
            onPressed: () => _authenticate(context),
            tooltip: 'Authenticate to Reddit',
            child: Icon(Icons.login),
          );
        return w;
      }), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _authenticate(BuildContext context) {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit.authenticate();
  }

  /// the main body of this page; this is the list that loads submissions (i.e
  /// posts or articles)
  Widget _getMainList(SubredditCubit subredditCubit) {
    Widget w = BlocBuilder<SubredditCubit, List<SubmissionItem>>(
        cubit: subredditCubit,
        builder: (_, List<SubmissionItem> contentList) {
          return ListView.separated(
              separatorBuilder: (_, __) => Divider(),
              itemCount: contentList.length,
              itemBuilder: (_, int index) {
                return createListTile(subredditCubit, contentList, index);
              });
        });
    w = RefreshIndicator(
        onRefresh: () => Future<void>( () => subredditCubit.clear()),
        child: w);
    w = NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo ) {
        if( scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent )
          subredditCubit.loadMore() ;
        return true ;
      },
      child: w
    ) ;
    return w ;
  }

  /// this is the main list tile that will go in the list
  Widget createListTile(SubredditCubit subredditCubit,
      List<SubmissionItem> contentList, int index) {
    Widget w, leading, trailing;
    String title, subtitle;

    if (contentList.length == 0) {
      leading = CircularProgressIndicator();
      title = 'Loading...';
      subtitle = '';
    } else {
      Submission s = contentList[index].submission;
      title = '${contentList[index].getTitle()}';
      subtitle =
          '${index}: ${contentList[index].getSubredditTitle()}: ${DateTimeFormatter.format(contentList[index].getTimestamp())}';
      Set<PostType> postTypes = contentList[index].getPostTypes();
      String avatar = (postTypes.length == 0)
          ? "?"
          : postTypes
              .map((p) => p.toShortString())
              .reduce((value, element) => value + element);
      Color avatarBackgroundColor = Colors.grey;
      Color avatarForegroundColor = Colors.white;
      if (postTypes.contains(PostType.BUY)) {
        avatarBackgroundColor = Colors.blueGrey;
      } else if (postTypes.contains(PostType.SELL)) {
        avatarBackgroundColor = Colors.lightGreen;
      }
      // if (postTypes.length > 1 ) {
      //   final hsl = HSLColor.fromColor( avatarBackgroundColor ) ;
      //   avatarBackgroundColor = hsl.withLightness( hsl.lightness + .2 ).toColor() ;
      // }
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

    return w;
  }

  /// used to launch the browser
  _launch(Uri shortlink) {
    print(shortlink);
    launch(shortlink.toString());
  }
}
