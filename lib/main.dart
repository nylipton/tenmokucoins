import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tenmoku_coins/display/DateTimeFormatter.dart';

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
              print('BlocBuilder called with $redditWrapper');
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

  Widget _getMainList(SubredditCubit subredditCubit) {
    Widget w = BlocBuilder<SubredditCubit, List<SubmissionItem>>(
        cubit: subredditCubit,
        builder: (_, List<SubmissionItem> contentList) {
          return ListView.builder(
            itemCount: contentList.length,
            itemBuilder: (_, int index) {
              return ListTile(
                leading: Icon(Icons.new_releases),
                title: Text("${contentList[index].getSubredditTitle()}: ${contentList[index].getTitle()}"),
                subtitle: Text( DateTimeFormatter.format( contentList[index].getTimestamp( ) ) ),
                dense: true,
              );
            },
          );
        });
    return w;
  }
}
