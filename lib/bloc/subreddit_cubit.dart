import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';

class SubredditCubit extends Cubit<List<SubmissionItem>> {
  Map<String, StreamSubscription<UserContent>> _redditStreamMap = {};

  SubredditCubit() : super([]);

  /// Sets the Reddit content stream that this will listen to in order
  /// to update the content. This can be called multiple times for different
  /// subreddits. If a name is added which it's already listening to, it will
  /// cancel the old stream and listen to the new one.
  void setStream(String subreddit, Stream<UserContent> contentStream) {
    _redditStreamMap[subreddit]?.cancel(); // in case this was already listening
    this._redditStreamMap[subreddit] = contentStream.listen(_process);
  }

  /// listen function for Reddit content
  void _process(UserContent event) {
    SubmissionItem submissionItem = SubmissionItem(event) ;
    print( 'Got new subreddit content: $submissionItem' ) ;
    state.add( submissionItem );
    state.sort((a,b) => b.getTimestamp().compareTo(a.getTimestamp()) ) ;
    emit(state);
  }
}

/// a reddit submission (i.e. the post)
class SubmissionItem extends Equatable {
  final Set<PostType> _postTypes;
  final Submission _submission;

  SubmissionItem(this._submission)
      : _postTypes = parsePostTypes(_submission.title.substring(0, 10));

  /// post's title
  String getTitle() => _submission.title;

  /// ex: coins4sale or pmsforsale
  String getSubredditTitle() => _submission.subreddit.displayName;

  /// when it was approved
  DateTime getTimestamp( ) => _submission.createdUtc.toLocal() ;

  Set<PostType> getPostTypes( ) => _postTypes ;

  @override
  // TODO: implement props
  List<Object> get props =>
      [_submission.subreddit.displayName, _submission.title, _submission.id];

  @override
  bool get stringify => true;

  static Set<PostType> parsePostTypes(String s) {
    Set<PostType> types = {};
    if (s.contains('WTB')) types.add(PostType.BUY);
    if (s.contains('WTS')) types.add(PostType.SELL);
    if (s.contains('WTT')) types.add(PostType.TRADE);
    return types;
  }
}

/// Is this a post to sell, buy or trade? Note that a post might refer to multiple
enum PostType { SELL, BUY, TRADE }
