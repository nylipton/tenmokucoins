import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tenmoku_coins/display/submission_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

/// A tile representing a submission (i.e. a Reddit Post).
class SubmissionTile extends StatelessWidget {
  final SubmissionWrapper _submissionWrapper ;

  SubmissionTile(this._submissionWrapper): super( key: ValueKey(_submissionWrapper.id));

  @override
  Widget build(BuildContext context) {
    Widget w, leading, trailing;


      Color avatarBackgroundColor = _submissionWrapper.hasMatch
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.primaryVariant;
      Color avatarForegroundColor = _submissionWrapper.hasMatch
          ? Theme.of(context).colorScheme.onSecondary
          : Theme.of(context).colorScheme.onPrimary;

      leading = CircleAvatar(
        child: Text(_submissionWrapper.avatarString,
            style: TextStyle(color: avatarForegroundColor)),
        backgroundColor: avatarBackgroundColor,
      );
      trailing = GestureDetector(
          behavior: HitTestBehavior.opaque,
          // TODO figure out why this is taking over taps even if the appbar is over it
          onTap: () => _launch(_submissionWrapper.item.submission.url),
          child: Icon(
            Icons.keyboard_arrow_right,
          ));


    List<WidgetSpan> tagWidgets = _submissionWrapper.matchingTags.map((tag) {
      return WidgetSpan(
          child: Badge(
            padding: EdgeInsets.fromLTRB(3, 0, 3, 0),
            shape: BadgeShape.square,
            badgeColor: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(15.0),
            badgeContent:
            Text(tag, style: Theme.of(context).textTheme.bodyText1),
            elevation: 0.0,
          ),
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic);
    }).toList();

    w = ListTile(
        leading: leading,
        title: Text.rich(
          TextSpan(
              text: _submissionWrapper.title + ' ',
              children: tagWidgets.toList()),
        ),
        subtitle: Text(_submissionWrapper.subtitle),
        dense: true,
        trailing: trailing);

    /// the column is to include a divider
    w = Column(
      children: [
        w,
        Divider(
          height: 0,
        )
      ],
    );

    return w;
  }

  /// used to launch the browser
  _launch(Uri shortlink) {
    launch(shortlink.toString());
  }
}
