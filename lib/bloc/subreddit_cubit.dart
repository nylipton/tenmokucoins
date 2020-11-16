import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';

/// This represents a Subreddit's list of submissions (i.e. posts)
class SubredditCubit extends Cubit<List<SubmissionItem>> {
  /// the number of submissions to load at a time
  static const int defaultLoadingNum = 20;
  static const subredditName = 'pmsforsale+coins4sale';
  final Reddit _reddit;

  /// the ID of the last received submission; used so we can ask for more
  String _lastId;

  /// A map of subreddit name to the last submission's ID. Used for pagination.
  // Map<String, String> _lastIDMap = {};

  SubredditCubit(this._reddit) : super([]) {
    _initList();
  }

  @override
  void onChange(Change<List> change) {
    print('next state has ${change.nextState.length} items');
    super.onChange(change);
  }

  /// initializes the list by calling the Reddit API for the newest posts
  void _initList({int num = defaultLoadingNum}) {
    SubredditRef subredditRef = _reddit.subreddit(subredditName);
    subredditRef.newest(limit: num).listen(_process);
  }

  /// listen function for Reddit content
  void _process(UserContent event) {
    SubmissionItem submissionItem = SubmissionItem(event);
    // print('Got new subreddit content: $submissionItem');
    _lastId = submissionItem.getId();

    /// todo, this only works if it comes in chronologically
    if (state.contains(submissionItem))
      print('got duplicate ');
    else {
      state.add(submissionItem);
      state.sort((a, b) => b.getTimestamp().compareTo(a.getTimestamp()));
      emit(new List<SubmissionItem>.from(state));
    }
  }

  /// load more submissions
  void loadMore() {
    const moreToLoad = 20 ;
    print(
        '****************** Loading another $moreToLoad Reddit submissions after $_lastId...');

    SubredditRef subredditRef = _reddit.subreddit(subredditName);
    subredditRef
        .newest(limit: state.length + moreToLoad, after: 't5_$_lastId')
        .listen(_process);
  }

  /// Clears this of all pre-loaded items and then loads the same number
  clear() {
    int num = state.length;
    emit([]);
    _initList(num: num);
  }
}

/// a reddit submission (i.e. the post)
class SubmissionItem extends Equatable {
  final Set<PostType> _postTypes;
  final Submission submission;

  SubmissionItem(this.submission)
      : _postTypes = parsePostTypes(submission.title.substring(0, 8));

  /// post's title
  String getTitle() => submission.title;

  /// ex: coins4sale or pmsforsale
  String getSubredditTitle() => submission.subreddit.displayName;

  /// when it was approved
  DateTime getTimestamp() => submission.createdUtc.toLocal();

  Uri getThumbnail() {
    Uri uri = submission.thumbnail;
    print('thumbnail uri:${submission.thumbnail}');
    return uri.toString().isEmpty ? null : uri;
  }

  Set<PostType> getPostTypes() => _postTypes;

  @override
  // TODO: implement props
  List<Object> get props =>
      [submission.subreddit.displayName, submission.title, submission.id];

  @override
  bool get stringify => true;

  static Set<PostType> parsePostTypes(String s) {
    Set<PostType> types = {};
    if (s.contains('WTB')) types.add(PostType.BUY);
    if (s.contains('WTS')) types.add(PostType.SELL);
    if (s.contains('WTT')) types.add(PostType.TRADE);
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
