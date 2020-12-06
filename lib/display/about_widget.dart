import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showCupertinoAbout({BuildContext context}) {
  showCupertinoDialog(
      context: context,
      builder: (c) {
        return CupertinoAlertDialog(
            title: Text('About'),
            content: AboutWidget(),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text('Licenses'),
                onPressed: () {
                  Navigator.of(c, rootNavigator: true).pop(false);
                  showLicensePage(context: context);
                },
              ),
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () =>
                    Navigator.of(c, rootNavigator: true).pop(false),
              )
            ]);
      });
}

/// Helps make the about dialog
class AboutWidget extends StatelessWidget {
  final String name;

  static const String defaultName = 'Tenmoku Coins';

  final Icon icon;

  final String version;

  static const String defaultVersion = 'v0.1';

  final String legalese;

  static const defaultLegalese = 'Copyright 2020, Tenmoku LLC';

  AboutWidget(
      {this.name = defaultName,
      this.icon,
      this.version = defaultVersion,
      this.legalese = defaultLegalese});

  @override
  Widget build(BuildContext context) {
    return ListBody(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (icon != null)
              IconTheme(data: Theme.of(context).iconTheme, child: icon),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListBody(
                  children: <Widget>[
                    Text(name, style: Theme.of(context).textTheme.headline6),
                    Text(version, style: Theme.of(context).textTheme.bodyText2),
                    const SizedBox(height: 5.0),
                    Text(legalese, style: Theme.of(context).textTheme.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
        ...?getChildren(context),
      ],
      // scrollable: true,
    );
  }

  static List<Widget> getChildren(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.bodyText2;
    return <Widget>[
      SizedBox(height: 24),
      RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
                style: textStyle,
                text: "Tenmoku Coins is for those "
                    'who love numismatics and precious metals. The goal '
                    'is making it easy to buy, sell and trade on Reddit. '
                    'It\'s free, open-source, and doesn\'t collect your data.\n\n'
                    'Learn more at '),
            TextSpan(
                style: textStyle.copyWith(color: Theme.of(context).accentColor),
                text: 'https://github.com/nylipton/tenmokucoins'),
            TextSpan(style: textStyle, text: '.'),
          ],
        ),
      ),
    ];
  }
}
