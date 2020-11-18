import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/reddit_client_cubit.dart';
import 'bloc/subreddit_cubit.dart';
import 'display/listings_page.dart';

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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<RedditClientCubit>(
            create: (context) => RedditClientCubit(),
          ),
          BlocProvider<SubredditBloc>(create: (context) {
            var bloc = SubredditBloc();
            bloc.setRedditClientCubit(
                BlocProvider.of<RedditClientCubit>(context));
            return bloc;
          }),
        ],
        child: ListingsPage(title: 'Tenmoku Coins'),
      ),
    );
  }
}
