import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chips_choice/chips_choice.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

var logger = Logger();

/// the name for custom tags
const customGroup = 'Custom';

/// The page used by users to indicate what tags they are interested in, such as
/// 'eagles' or 'silver'
class InterestsPage extends StatelessWidget {
  static const title = 'Interests';

  /// Tags are the list of strings that users are interested in. Note that
  /// this field is only used to initialize the [TagsCubit].
  final _tags;

  InterestsPage(this._tags) : assert(_tags != null) {
    // Find all of the custom tags and put them in the [customGroup]
    List<String> tmpTags = [..._tags]; // make a copy
    interestOptions.keys.forEach((group) {
      _tags.forEach((tag) {
        if (interestOptions[group].contains(tag)) tmpTags.remove(tag);
      });
    });
    tmpTags.sort();
    interestOptions[customGroup] = tmpTags;
  }

  // TODO add WTB, WTS, WTT as tags; make this a separate filter?
  final Map<String, List<String>> interestOptions = {
    customGroup: [],
    "PM's": ["Silver", "Gold", "Platinum", "Paladium"],
    "PM Coins": [
      "Maple",
      "Sovereign",
      "Eagle",
      "ASE",
      "Panda",
      "Rounds",
      "Aztec",
      "Libertad",
      "Onza",
      "Queens Beast",
      "Australia Lunar",
      "5oz ATB",
      "World Silver",
      "Krugerand",
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
      "Scottsdale",
      "10K",
      "14K",
      "18K",
      "999",
      "9999",
      "99999",
      "925",
      "90%",
      "Sterling",
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
      "CAC",
      "Tone"
    ]
  };

  @override
  Widget build(BuildContext context) {
    InterestOptionsCubit interestOptionsCubit =
        InterestOptionsCubit(interestOptions);
    TagsCubit tagsCubit = TagsCubit(_tags, interestOptionsCubit);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (_) => interestOptionsCubit,
        ),
        BlocProvider(lazy: false, create: (_) => tagsCubit)
      ],
      child: InterestsPageScaffold(),
    );
  }
}

/// This is the main body of the page; it varies by whether it's iOS or other.
class InterestsPageScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget w;
    final tagsCubit = BlocProvider.of<TagsCubit>(context);

    if (Platform.isIOS) {
      w = CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          // leading: GestureDetector(
          //   onTap: () => Navigator.pop( context ),
          //   child: Icon( CupertinoIcons.xmark, color: Theme.of( context ).colorScheme.onBackground,)
          // ),
          trailing: GestureDetector(
              child: Text('Save',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)),
              onTap: () => _save(context: context, tags: tagsCubit.state)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actionsForegroundColor: Theme.of(context).colorScheme.onPrimary,
          middle: Text(
            InterestsPage.title,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        child: InterestSection(),
      );
    } else {
      // Material implementation
      w = Scaffold(
          appBar: AppBar(
            title: Text(InterestsPage.title),
            actions: [
              FlatButton(
                child: Text(
                  'SAVE',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                onPressed: () => _save(context: context, tags: tagsCubit.state),
              )
            ],
          ),
          body: Center(child: InterestSection()));
    }

    return w;
  }

  /// Returns the selected tags back to the caller by popping
  void _save({@required BuildContext context, List<String> tags}) {
    logger.d('Saving new filter settings: $tags');
    Navigator.pop(context, tags);
  }
}

/// This is the list of interests where the user can select his tags. It holds a
/// number of [Content] widgets.
class InterestSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    {
      // InterestOptionsCubit interestOptionsCubit =
      //     BlocProvider.of<InterestOptionsCubit>(context);
      // var interestOptions = interestOptionsCubit.state;

      // TagsCubit tagsCubit = BlocProvider.of<TagsCubit>(context);
      // var tags = tagsCubit.state;
      return BlocBuilder<TagsCubit, List<String>>(builder: (_, tags) {
        return BlocBuilder<InterestOptionsCubit, Map<String, List<String>>>(
            builder: (c, interestOptions) {
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: ListView.builder(
              addAutomaticKeepAlives: true, // ???
              semanticChildCount: interestOptions.length,
              itemCount: interestOptions.length,
              itemBuilder: (_, index) {
                String section = interestOptions.keys.toList()[index];
                Widget chipsWidget;
                if (interestOptions[section].length == 0)
                  chipsWidget = Container();
                else
                  chipsWidget = Material(
                    child: ChipsChoice<String>.multiple(
                      choiceActiveStyle: C2ChoiceStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          brightness: Brightness.dark),
                      value: tags,
                      onChanged: (val) =>
                          BlocProvider.of<TagsCubit>(c).set(val),
                      choiceItems: C2Choice.listFrom<String, String>(
                          source: interestOptions[section],
                          value: (i, v) => v,
                          label: (i, v) => v,
                          tooltip: (i, v) => v),
                      wrapped: true,
                    ),
                  );
                return Content(title: section, child: chipsWidget);
              },
            ),
          );
        });
      });
    }
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
    var _formKey = GlobalKey<FormState>();
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
              padding: const EdgeInsets.fromLTRB( 15,10,15,0),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            if (widget.title == customGroup)
              Form(
                  key: _formKey,
                  child: Container(
                      padding: const EdgeInsets.fromLTRB( 15,0,15,0),
                      child:TextFormField(
                    minLines: 1,
                    maxLines: 1,
                    validator: (val) {
                      return (tagExists(context, val)
                          ? 'This interest tag is already defined'
                          : null);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      // contentPadding: const EdgeInsets.fromLTRB( 15,0,15,0),
                      hintText: 'Custom tag',
                    ),
                    onFieldSubmitted: (v) => _formKey.currentState.validate()
                        ? addTag(context, v)
                        : null,
                  ))),
            Flexible(fit: FlexFit.loose, child: widget.child),
          ],
        ),
      ),
    );
  }

  addTag(BuildContext context, String name) {
    BlocProvider.of<TagsCubit>(context).add(name);
  }

  bool tagExists(context, String name) {
    return BlocProvider.of<InterestOptionsCubit>(context).hasTag(name);
  }
}

/// Represents the current list of interests the user can select
class InterestOptionsCubit extends Cubit<Map<String, List<String>>> {
  InterestOptionsCubit(Map<String, List<String>> state)
      : assert(state != null),
        super(state);

  /// Note: makes a deep copy
  set(Map<String, List<String>> val) {
    Map<String, List<String>> newMap = {};
    state.keys.forEach((group) => newMap[group] = [...state[group]]);
    emit(newMap);
  }

  /// Adds the given tag, if it wasn't already in it. Adds the group if it isn't
  /// already there
  void add({String group = customGroup, String tag}) {
    assert(tag != null);
    assert(state != null);
    if (state[group] == null) state[group] = <String>[];

    if (!hasTag(tag)) {
      if (!state[group].contains(tag)) state[group].add(tag);
      set(state);
    }
  }

  /// returns if this tag is already defined anywhere
  bool hasTag(String name) {
    assert(name != null);
    bool exists = false;
    state.keys.forEach((key) => state[key].forEach((val) =>
        exists = (val.toLowerCase() == name.toLowerCase()) ? true : exists));
    return exists;
  }
}

/// Represents the currently selected list of tags that the user's interested in.
class TagsCubit extends Cubit<List<String>> {
  TagsCubit(List<String> state, this._interestOptionsCubit) : super(state);
  InterestOptionsCubit _interestOptionsCubit;

  /// Note: makes a copy of the list
  set(List<String> val) => emit([...val]);

  /// Adds this tag to the list of selected tags, if it isn't already in there.
  /// Returns whether it successfully added the name (i.e. false if it was already
  /// in there).
  bool add(String name) {
    assert(name != null);

    bool success;
    if (!state.contains(name)) {
      emit([name, ...state]);
      _interestOptionsCubit.add(tag: name);
      success = true;
    } else {
      success = false;
    }

    logger.d(
        'User added $name as a tag ${success ? 'successfully' : 'unsuccessfully'}');
    return success;
  }
}
