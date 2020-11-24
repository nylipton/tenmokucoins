
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/subreddit_bloc.dart';

import 'listings_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
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
    ) ;
  }
}