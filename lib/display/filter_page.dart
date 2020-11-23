import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chips_choice/chips_choice.dart';
import 'package:logger/logger.dart';

class FilterPage extends StatefulWidget {
  static const title = 'Filter';
  final tags ;

  @override
  _FilterPageState createState() => _FilterPageState(tags: tags);

  FilterPage({this.tags});
}

class _FilterPageState extends State<FilterPage> {
  var logger = Logger();
  // TODO add WTB, WTS, WTT as tags; make this a separate filter?
  final Map<String, List<String>> filterOptions = {
    "PM's": ["Silver", "Gold", "Paladium"],
    "PM Coins": [
      "Maple",
      "Sovereign",
      "Eagle",
      "ASE",
      "Panda",
      "Rounds",
      "Aztec",
      "Libertad",
      "Queens Beast",
      "Australia Lunar",
      "5oz ATB",
      "World Silver",
      "Krugerand"
          "Junk"
    ],
    "PM Other": [
      "Valcambi",
      "Silver bar",
      "art bar",
      "gold bar",
      "Maplegram",
      "Prospector",
      "Goldback",
      "Scrap",
      "Englehard",
      "Scottsdale"
          "10K",
      "14K",
      "18K",
      "999",
      "9999",
      "99999",
      "925",
      "90%",
      "Bracelet",
      "Jewlry",
      "Earing",
      "Ring",
      "50oz",
      "100oz"
    ],
    "U.S. Numismatics": [
      "Walking Liberty",
      "Morgans",
      "Wheaties",
      "Lincoln",
      "Double Eagle",
      "Half Eagle",
      "Indian",
      "Peace Dollar",
      "Benji",
      "Benjamin",
      "half dollar",
      "Walking Liberty",
      "Kennedy",
      "Ike",
      "Eisenhower",
      "Washington",
      "ATB",
      "Merc",
      "Dime"
    ],
    "World Numismatics": [
      "Ruble",
      "Ancient",
      "Roman",
      "Centavos",
      "8 Reales",
      "Golden Horde",
      "Kopek",
      "Franc",
      "Dos Pesos",
      "Thaler"
    ],
    "Other": [
      "Graded",
      "BU",
      "Slabbed",
      "Rattler",
      "Fatty",
      "Notes",
      "Proof",
      "Copper",
      "Danco",
      "Album",
      "Commem",
      "Modern Commem",
      "Key Date",
      "Semi-Key Date",
      "CAC"
    ]
  };

  /// The applied tags (i.e. the selected chips)
  List<String> tags = [];

  _FilterPageState({this.tags});

  @override
  void initState() {
    super.initState() ;
    if( tags == null )
      tags = [] ;
  }

  @override
  Widget build(BuildContext context) {
    Widget w;

    if (Platform.isIOS) {
      w = CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          // leading: GestureDetector(
          //   onTap: () => Navigator.pop( context ),
          //   child: Icon( CupertinoIcons.xmark, color: Theme.of( context ).colorScheme.onBackground,)
          // ),
          trailing: GestureDetector(
            child: Text('Save',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            onTap: () => _save()
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actionsForegroundColor: Theme.of(context).colorScheme.onPrimary,
          middle: Text(
            FilterPage.title,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        child: _filterForm(),
      );
    } else { // Material implementation
      w = Scaffold(
        appBar: AppBar(
          title: Text(FilterPage.title),
          actions: [
            FlatButton(
              child: Text(
                'SAVE',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
              onPressed: _save,
            )
          ],
        ),
        body: Center(
          child: _filterForm(),
        ),
      );
    }

    return w;
  }

  _filterForm() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ListView.builder(
        addAutomaticKeepAlives: true, // ???
        semanticChildCount: filterOptions.length,
        itemCount: filterOptions.length,
        itemBuilder: (_, index) {
          String section = filterOptions.keys.toList()[index];
          return Content(
              title: section,
              child: Material(
                child: ChipsChoice<String>.multiple(
                  choiceActiveStyle: C2ChoiceStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      brightness: Brightness.dark),
                  value: tags,
                  onChanged: (val) => setState(() => tags = val),
                  choiceItems: C2Choice.listFrom<String, String>(
                      source: filterOptions[section],
                      value: (i, v) => v,
                      label: (i, v) => v,
                      tooltip: (i, v) => v),
                  wrapped: true,
                ),
              ));
        },
      ),
    );
  }

  void _save() {
    logger.d('Saving new filter settings: $tags');
    // TODO save the new filters to a bloc
    Navigator.pop( context, tags ) ;
  }
}

/// The filter contents, implemented with chips
class Content extends StatefulWidget {
  final String title;
  final Widget child;

  Content({
    Key key,
    @required this.title,
    @required this.child,
  }) : super(key: key);

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content>
    with AutomaticKeepAliveClientMixin<Content> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Material(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(5),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(15),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Flexible(fit: FlexFit.loose, child: widget.child),
          ],
        ),
      ),
    );
  }
}
