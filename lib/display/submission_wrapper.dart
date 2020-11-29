
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/subreddit_bloc.dart';

import 'DateTimeFormatter.dart';

/// Holds a Reddit [SubmissionItem] and provides display facilities such as the
/// title to be shown and whether it matches a filter highlight list
class SubmissionWrapper {
  static final Logger logger = Logger();
  final SubmissionItem item;
  bool _hasMatch = false;
  String _title;
  String _avatarString;

  String _subtitle;

  List<String> _matchingTags = [];

  SubmissionWrapper({this.item, List<String> tags = const []})
      : assert(item != null) {
    tags.forEach((tag) {
      RegExp regex = RegExp(tag, caseSensitive: false);
      if (regex.firstMatch(item.getTitle()) != null ||
          (item.submission.isSelf &&
              regex.firstMatch(item.submission.selftext) != null)) {
        _matchingTags.add(tag);
        _hasMatch = true;
      }
    });

    StringBuffer sb = StringBuffer();
    sb.write(item
        .getTitle()
        .replaceAll(RegExp("\\[[Ww][Tt][bBsStT]\\][\s\\\/\,]*"), "")
        .replaceAll(RegExp("^\\s*"), "")
        .replaceAll(RegExp("&amp;"), "&"));
    _title = sb.toString();

    _subtitle =
    '${item.getSubredditTitle()}: ${DateTimeFormatter.format(item.getTimestamp())}';

    Set<PostType> postTypes = item.getPostTypes();
    _avatarString = (postTypes.length == 0)
        ? "?"
        : postTypes
        .map((p) => p.toShortString())
        .reduce((value, element) => value + '/' + element);
  }

  /// The display title
  String get title => _title;

  /// Subreddit and posting time
  String get subtitle => _subtitle;

  /// B, S or T depending on the post type (i.e. buy, sell or trade)
  String get avatarString => _avatarString;

  /// Did any of the tags match?
  bool get hasMatch => _hasMatch;

  /// Which tags matched?
  List<String> get matchingTags => _matchingTags;

  /// The id of a Reddit object.
  ///
  /// Reddit object ids take the form of '15bfi0'.
  String get id => item.getId() ;
}
