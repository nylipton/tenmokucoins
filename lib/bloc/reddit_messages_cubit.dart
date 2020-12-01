import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';

part 'reddit_messages_state.dart';

/// Cubit for the list of user messages on Reddit
class RedditMessagesCubit extends Cubit<BaseRedditMessagesState> {
  final Logger logger = Logger();

  RedditMessagesCubit() : super(UnauthenticatedUserState());

  void setRedditClientCubit({RedditClientCubit clientCubit}) {
    clientCubit.listen((redditWrapper) {
      if (redditWrapper != null && redditWrapper.isAuthenticated()) {
        logger.d(
            'Notified of an updated authenticated Reddit user by RedditClientCubit.');
        emit(UpdatedRedditMessagesState([]));
        var messageStream = redditWrapper.reddit.inbox.messages();
        messageStream.listen((msg) => _processNewMessage(msg));
      } else {
        logger.d(
            'Notified of an unauthenticated Reddit user by RedditClientCubit.');
        emit(UnauthenticatedUserState());
      }
    });
  }

  void _processNewMessage(Message msg) {
    emit(UpdatedRedditMessagesState.constructWithNewMessage(
        oldState: state, message: msg));
  }
}
