import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'dart:math';

/// This represents a Subreddit's list of submissions (i.e. posts)
class SubredditBloc extends Bloc<SubredditListEvent, SubredditListState> {
  final logger = Logger();

  /// The names of the subreddits to load
  static const subredditName = 'pmsforsale+coins4sale';

  /// the [Reddit] instance
  Reddit _reddit;

  /// The default number of submissions to request from Reddit
  static const defaultLoadingNum = 20;

  /// The number of submissions this Bloc should have received when done with
  /// the current load.
  /// Hmm.... Should this be in the [SubredditListLoadingState] object?
  int _numSubmissionsGoal = 0;

  /// For listening to changes in the RedditCubit
  StreamSubscription _redditCubitStreamSubscription;

  /// Don't forget to set the [RedditClientCubit] in [setRedditClientCubit]
  SubredditBloc() : super(SubredditRawState());

  /// This is so it knows when there is an authenticated or untrusted user, or
  /// none at all. Until the [RedditClientCubit] tells this that there's a
  /// [Reddit] instance it won't ask for submissions.
  // TODO validate that this is getting callbacks from the [RedditClientCubit]
  void setRedditClientCubit(RedditClientCubit clientCubit) {
    logger.v('SubredditBloc is listening to the RedditClientCubit');
    // if (clientCubit.state != null && clientCubit.state.reddit != null) {
    //   logger.d('SubredditBloc is setting the Reddit instance');
    //   _reddit = clientCubit.state.reddit;
    //   add(SubredditListClearEvent());
    // }
    _redditCubitStreamSubscription = clientCubit.listen((redditWrapper) {
      logger.d(
          'SubredditBloc has been notified of an update by RedditClientCubit.');
      add(SubredditListNewRedditClientEvent(redditWrapper.reddit));
    });
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    add(SubredditListErrorEvent(error.toString()));
    super.onError(error, stackTrace);
  }

  @override
  Stream<SubredditListState> mapEventToState(SubredditListEvent event) async* {
    logger.v('SubredditBloc received an event: $event while in state: $state');
    if (event is SubredditListLoadSubmissions) {
      yield* _mapLoadSubmissions(event);
    } else if (event is SubredditListClearEvent) {
      yield* _mapClearList(event);
    } else if (event is SubredditListNewSubmissionReceived) {
      yield await _mapSubmissionReceived(event);
    } else if (event is SubredditListErrorEvent) {
      _numSubmissionsGoal = state.submissions.length;
      yield SubredditListDoneState(state.submissions, state.lastId);
    } else if (event is SubredditListNewRedditClientEvent) {
      _numSubmissionsGoal = 0;
      if (event.reddit == null) {
        logger.d('Got assigned a new reddit instance that\'s null');
        yield SubredditRawState();
      } else {
        logger.d('Got assigned a new reddit instance that\'s not null');
        _reddit = event.reddit;
        yield SubredditListDoneState([], null);
        add(SubredditListClearEvent());
      }
    } else {
      logger.w('SubredditBloc got unknown event $event');
      addError(Exception('unsupported event'));
    }
  }

  Future<SubredditListState> _mapSubmissionReceived(
      SubredditListNewSubmissionReceived event) async {
    logger.v('Got new subreddit content: ${event.item}');
    String lastId = event.item.getId();

    if (state.submissions != null && state.submissions.contains(event.item)) {
      logger.i('Received and ignoring a duplicate submission');
      return state;
    } else if (state is SubredditRawState) {
      logger.i(
          'Received (and ignoring) a submission from reddit while in raw state: ${event.item}');
      return state;
    } else {
      var list = state.submissions;
      list.add(event.item);
      list.sort((a, b) => b.getTimestamp().compareTo(a.getTimestamp()));
      if (list.length == _numSubmissionsGoal)
        return SubredditListDoneState(
            new List<SubmissionItem>.from(state.submissions), lastId);
      else
        return SubredditListLoadingState(
            new List<SubmissionItem>.from(state.submissions), lastId);
    }
  }

  /// if this is in the done state (i.e. not in the middle of loading)
  /// then clear the list and call [_requestSubmissions] to load an initial list of
  /// submissions
  Stream<SubredditListState> _mapClearList(
      SubredditListClearEvent event) async* {
    if (state is SubredditListDoneState || state is SubredditRawState) {
      _numSubmissionsGoal = 0;
      yield SubredditListDoneState([], null);
      add(SubredditListLoadSubmissions());
    }
  }

  /// this will load some more posts if the state is done; it will ignore the
  /// request if it's raw or currently loading
  Stream<SubredditListState> _mapLoadSubmissions(
      SubredditListLoadSubmissions event) async* {
    if (state is SubredditListDoneState) {
      // TODO start a timer to force this out of the loading state if it's taking too long
      yield SubredditListLoadingState(state.submissions, state.lastId);
      _requestSubmissions(num: event.numberToLoad);
    }
  }

  /// Calls the Reddit API for the newest posts
  void _requestSubmissions({int num = defaultLoadingNum}) {
    assert(_reddit != null);
    SubredditRef subredditRef = _reddit.subreddit(subredditName);

    if (state.lastId == null) {
      _numSubmissionsGoal = num;
      logger.d('SubredditBloc is requesting $num new submissions.');
      subredditRef.newest(limit: num).listen(_process).onError((e) {
        logger.e('Unable to make Reddit request', e);
        addError('Unable to make Reddit request');
      });
    } else {
      _numSubmissionsGoal += num;
      String after = 't3_' + state.lastId;
      logger.d('SubredditBloc is requesting $num new submissions after $after');
      subredditRef
          .newest(limit: num, after: after)
          .listen(_process)
          .onError((e) {
        logger.e('Unable to make Reddit request', e);
        addError('Unable to make Reddit request');
      });
    }
  }

  /// listen function for Reddit content
  void _process(UserContent event) {
    SubmissionItem submissionItem = SubmissionItem(event);
    add(SubredditListNewSubmissionReceived(submissionItem));
  }

  @override
  Future<Function> close() {
    _redditCubitStreamSubscription.cancel();
    return super.close();
  }
}

/// a reddit submission (i.e. the post)
class SubmissionItem extends Equatable {
  final logger = Logger();
  final Set<PostType> _postTypes;
  final Submission submission;

  SubmissionItem(this.submission)
      : _postTypes = parsePostTypes(
            submission.title.substring(0, min(15, submission.title.length)));

  /// post's title
  String getTitle() => submission.title;

  /// ex: coins4sale or pmsforsale
  String getSubredditTitle() => submission.subreddit.displayName;

  /// when it was approved
  DateTime getTimestamp() => submission.createdUtc.toLocal();

  Uri getThumbnail() {
    Uri uri = submission.thumbnail;
    logger.d('thumbnail uri:${submission.thumbnail}');
    return uri.toString().isEmpty ? null : uri;
  }

  Set<PostType> getPostTypes() => _postTypes;

  @override
  List<Object> get props =>
      [submission.subreddit.displayName, submission.title, submission.id];

  @override
  bool get stringify => true;

  static Set<PostType> parsePostTypes(String s) {
    Set<PostType> types = {};
    if (s.toUpperCase().contains('WTB')) types.add(PostType.BUY);
    if (s.toUpperCase().contains('WTS')) types.add(PostType.SELL);
    if (s.toUpperCase().contains('WTT')) types.add(PostType.TRADE);
    return types;
  }

  String getId() => submission.id;
}

/// Is this a post to sell, buy or trade? Note that a post might refer to multiple
enum PostType { SELL, BUY, TRADE }

extension PostString on PostType {
  String toShortString() {
    String shortString;
    if (this == PostType.SELL)
      shortString = 'S';
    else if (this == PostType.BUY)
      shortString = 'B';
    else
      shortString = 'T';
    return shortString;
  }
}

/// base state class
abstract class SubredditListState extends Equatable {
  final List<SubmissionItem> submissions;

  /// the ID of the last received submission; used so we can ask for more
  final String lastId;
  static const List emptyList = <SubmissionItem>[];

  const SubredditListState(this.submissions, this.lastId);

  @override
  List<Object> get props => [...submissions];

  @override
  bool get stringify => true;
}

/// this is the state for when there is no reddit client
class SubredditRawState extends SubredditListState {
  const SubredditRawState() : super(SubredditListState.emptyList, null);
}

/// more subreddit submissions are currently loading
class SubredditListLoadingState extends SubredditListState {
  const SubredditListLoadingState(
      List<SubmissionItem> submissions, String lastId)
      : super(submissions, lastId);

  @override
  String toString() => 'SubredditLoadingState { length: ${submissions.length}}';
}

/// more subreddit submissions are currently loading
class SubredditListDoneState extends SubredditListState {
  const SubredditListDoneState(List<SubmissionItem> submissions, String lastId)
      : super(submissions, lastId);

  @override
  String toString() => 'SubredditDoneState { length: ${submissions.length}}';
}

/// base class for all of the [SubredditBloc]'s events
abstract class SubredditListEvent extends Equatable {
  const SubredditListEvent();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

/// Used when an error occurs (such as a rebuffed network request.
class SubredditListErrorEvent extends SubredditListEvent {
  final String error;

  SubredditListErrorEvent(this.error);

  @override
  List<Object> get props => [error];
}

/// Clear the list of subreddit submissions and then reload from scratch
class SubredditListClearEvent extends SubredditListEvent {}

/// Load the initial list of subreddit submissions (the number to load is optional)
class SubredditListLoadSubmissions extends SubredditListEvent {
  final numberToLoad;

  const SubredditListLoadSubmissions({this.numberToLoad = 20});

  @override
  List<Object> get props => [numberToLoad];
}

/// A new [SubmissionItem] is received and added to the list
class SubredditListNewSubmissionReceived extends SubredditListEvent {
  final SubmissionItem item;

  const SubredditListNewSubmissionReceived(this.item);

  @override
  List<Object> get props => [item];
}

/// Used when there is a new [RedditClient] set to the Bloc
class SubredditListNewRedditClientEvent extends SubredditListEvent {
  final Reddit reddit;

  const SubredditListNewRedditClientEvent(this.reddit);

  @override
  List<Object> get props => [reddit];
}
