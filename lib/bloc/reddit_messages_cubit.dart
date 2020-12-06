import 'dart:async';

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

  RedditWrapper _redditWrapper;

  StreamSubscription _redditWrapperSubscription;

  RedditMessagesCubit() : super(UnauthenticatedUserState());

  void setRedditClientCubit({@required RedditClientCubit clientCubit}) {
    if (clientCubit.state != null) {
      if (clientCubit.state.isAuthenticated()) {
        logger.d('Reddit is authenticated');
        _redditWrapper = clientCubit.state ;
        refresh(reddit: clientCubit.state.reddit);
      }
    }
    logger.d(
        'Setting redditClientCubit to $clientCubit. Listening for status updates.');
    _redditWrapperSubscription = clientCubit.listen((redditWrapper) {
      _redditWrapper = redditWrapper;
      if (redditWrapper != null && redditWrapper.isAuthenticated()) {
        logger.d(
            'Notified of an updated authenticated Reddit user by RedditClientCubit.');
        refresh(reddit: redditWrapper.reddit);
      } else {
        logger.d(
            'Notified of an unauthenticated Reddit user by RedditClientCubit.');
        emit(UnauthenticatedUserState());
      }
    });
  }

  /// Refreshes the list of messages
  void refresh({Reddit reddit}) {
    reddit ??= _redditWrapper?.reddit;
    if (_redditWrapper.isAuthenticated()) {
      emit(UpdatedRedditMessagesState([]));
      var messageStream = reddit.inbox.messages();
      messageStream?.listen((msg) => _processNewMessage(msg));
    } else {
      logger.e('Reddit isn\'t authenticated');
    }
  }

  void _processNewMessage(Message msg) {
    emit(UpdatedRedditMessagesState.constructWithNewMessage(
        oldState: state, message: msg));
  }

  void dispose() {
    _redditWrapperSubscription.cancel();
  }

  RedditWrapper get redditWrapper => _redditWrapper;
}
