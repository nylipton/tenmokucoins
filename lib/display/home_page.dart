
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/reddit_messages_cubit.dart';
import 'package:tenmoku_coins/bloc/subreddit_bloc.dart';

import 'main_page.dart';
import 'navigation_index_cubit.dart';

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
        BlocProvider<NavigationIndexCubit>(
          create: (context) => NavigationIndexCubit(0),
        ),
        BlocProvider<RedditMessagesCubit>(
          create: (context) {
            var cubit = RedditMessagesCubit() ;
            cubit.setRedditClientCubit( clientCubit: BlocProvider.of<RedditClientCubit>(context) ) ;
            return cubit ;
          },
        ),
      ],
      child: MainPage(title: 'Tenmoku Coins'),
    ) ;
  }
}