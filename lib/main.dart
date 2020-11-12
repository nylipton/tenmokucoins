import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bloc/reddit_client_cubit.dart';

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
            Center(child: BlocBuilder<RedditClientCubit, RedditWrapper>(
                builder: (_, redditWrapper) {
              print('BlocBuilder called with $redditWrapper');
              Widget w; //=Text('blah');
              if (redditWrapper.reddit == null)
                w = Text('Start authentication to login');
              else if (!redditWrapper.reddit.auth.isValid)
                w = Text('Not authenticated yet');
              else {
                print('BlocBuilder has an authenticated user');
                w = FutureBuilder(
                  future: redditWrapper.getUsername(),
                  builder: (_, AsyncSnapshot<String> snapshot) {
                    print(
                        'FutureBuilder listening for the Redditor has returned...');
                    if (snapshot.hasError) {
                      print(
                          'FutureBuilder got an error trying to get the Reddit user: $snapshot.error');
                      return Text(
                        'There was an error getting the user:\n$snapshot.error',
                        softWrap: true,
                      );
                    } else if (snapshot.hasData) {
                      print('...and it hasData');
                      return Text('You are user: ${snapshot.data}');
                    } else {
                      print('...but the snapshot has no data');
                      return Text('Waiting on the Reddit user...');
                    }
                  },
                );
              }
              return w;
            })),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<RedditClientCubit, RedditWrapper>(
          builder: (_, redditWrapper) {
            Widget w ;
        if (redditWrapper != null && redditWrapper.isAuthenticated())
          w = Container( );
        else
          w = FloatingActionButton(
            onPressed: () => _authenticate(context),
            tooltip: 'Authenticate to Reddit',
            child: Icon(Icons.login),
          );
        return w ;
      }), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _authenticate(BuildContext context) {
    RedditClientCubit redditCubit = BlocProvider.of(context);
    redditCubit.authenticate();
  }
}
