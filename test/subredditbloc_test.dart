import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';

void main() {
  group('RedditTest', () {
    // RedditClientCubit redditClientCubit ;
    // SubredditBloc subredditBloc ;
    // SimpleBlocObserver observer ;
    //
    // setUp( () {
    //   observer = SimpleBlocObserver() ;
    //   Bloc.observer = observer ;
    //   redditClientCubit = RedditClientCubit() ;
    // } ) ;
    //
    // tearDown( () {
    //   redditClientCubit.dispose() ;
    //   redditClientCubit?.redditWrapper?.getSubredditsBloc()?.close() ;
    // } ) ;

    blocTest('emits a RedditWrapper',
        build: () => RedditClientCubit(),
        wait: const Duration(seconds: 1),
        expect: [isA<RedditWrapper>()]);
  });
}
