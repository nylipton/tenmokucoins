import 'package:draw/draw.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/reddit_messages_cubit.dart';
import 'dart:io';

import 'package:tenmoku_coins/display/DateTimeFormatter.dart';

import '../main.dart';

class MessagesWidget extends StatefulWidget {
  MessagesWidget();

  @override
  _MessagesWidgetState createState() => _MessagesWidgetState();
}

final Logger logger = Logger();

class _MessagesWidgetState extends State<MessagesWidget> {
  // State variables
  List<Message> _messages;
  int _numNew;
  RedditWrapper _redditWrapper;

  bool _authenticated;
  static const _title = 'Messages';

  @override
  void initState() {
    super.initState();
    _messages = [];
    _numNew = 0;
    _authenticated = false;
    _redditWrapper = null;
    logger.v('Creating new _MessagesWidgetState object');
  }

  @override
  Widget build(BuildContext context) {
    Widget widget = _authenticated
        ? _messagesWidget()
        : Center(child: UnauthenticatedWidget());
    return MultiBlocListener(
      listeners: [
        BlocListener<RedditMessagesCubit, BaseRedditMessagesState>(
            listener: (BuildContext context, state) {
          setState(() {
            if (state is UnauthenticatedUserState) {
              _authenticated = false;
              _messages = [];
              _numNew = 0;
              _redditWrapper = null;
            } else {
              _redditWrapper =
                  BlocProvider.of<RedditMessagesCubit>(context).redditWrapper;
              _authenticated = true;
              _messages = state.messages;
              _messages
                  .sort((m1, m2) => m2.createdUtc.compareTo(m1.createdUtc));
              _numNew = _messages.isNotEmpty
                  ? _messages
                      .map((m) => (m.newItem ? 1 : 0))
                      .reduce((a, b) => a + b)
                  : 0;
            }
          });
        }),
      ],
      child: widget,
    );
  }

  Widget _messagesWidget() {
    var scrollView = CustomScrollView(
      slivers: [
        _navigationBar(context),
        if (Platform.isIOS) _iOSRefresh(context),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) {
              return MessageTile(_messages[index], _redditWrapper?.reddit);
            },
            childCount: _messages.length,
          ),
        )
      ],
      shrinkWrap: true,
    );
    if (!Platform.isIOS) {
      return RefreshIndicator(
          onRefresh: () => Future(
              () => BlocProvider.of<RedditMessagesCubit>(context).refresh()),
          child: scrollView);
    } else {
      return scrollView;
    }
  }

  Widget _iOSRefresh(BuildContext context) {
    return CupertinoSliverRefreshControl(
        onRefresh: () => Future<void>(
            () => BlocProvider.of<RedditMessagesCubit>(context).refresh()));
  }

  Widget _navigationBar(BuildContext context) {
    String title = _title;
    if (_numNew != 0) {
      title += ' (${_numNew} new)';
    }
    if (Platform.isIOS) {
      return CupertinoSliverNavigationBar(
          heroTag: 'message_list_page',
          transitionBetweenRoutes: false,
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary, // TODO See if this can be removed on iOS
          largeTitle: Text(title));
    } else {
      return SliverAppBar(
        elevation: 1.0,
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        pinned: false,
      );
    }
  }
}

/// Represents an individual message
class MessageTile extends StatelessWidget {
  final Message _message;
  final Reddit _reddit;
  static const default_img_url =
      'https://www.redditstatic.com/avatars/avatar_default_15_DB0064.png';
  final defaultAvatar;

  MessageTile(this._message, this._reddit)
      : assert(_reddit != null),
        defaultAvatar = const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(default_img_url));

  @override
  Widget build(BuildContext context) {
    int replies = 0;
    List<InlineSpan> firstLineChildren = (_message.distinguished != null)
        ? [
            TextSpan(
                text: ' [${_message.distinguished}]',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ]
        : [];
    try {
      replies = _message.replies.length;
      if (replies > 0) {
        firstLineChildren.add(
          TextSpan(
              text: '  (${replies.toString()})',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100)),
        );
      }
    } catch (e) {
      logger.v('no replies to message');
    }
    var fontWeight = _message.newItem ? FontWeight.bold : FontWeight.normal;
    var titleWidget = Row(children: [
      RichText(
        text: TextSpan(
            text: _message.author,
            style: DefaultTextStyle.of(context)
                .style
                .copyWith(fontSize: 16, fontWeight: fontWeight),
            children: firstLineChildren),
      ),
      Expanded(
        child: Container(),
      ),
      Text(DateTimeFormatter.dateFormat.format(_message.createdUtc))
    ]);

    RegExp regExp = RegExp("^(.*?)\.(jpg|png|gif)");
    var avatar = FutureBuilder<Redditor>(
        initialData: null,
        future: _reddit.redditor(_message.author).populate(),
        builder: (BuildContext context, AsyncSnapshot<Redditor> snapshot) {
          var avatar = defaultAvatar;
          if (snapshot.hasData) {
            var rawImageUrl = snapshot.data.data['icon_img'];
            if (rawImageUrl != null) {
              var match = regExp.firstMatch(rawImageUrl);
              var imageUrl = match?.group(0) ?? default_img_url;
              avatar = CircleAvatar(
                radius: 30,
                backgroundColor: Colors.transparent,
                backgroundImage: NetworkImage(imageUrl),
              );
            }
          }
          return avatar;
        });
    return Column(
      children: [
        Material(
          child: ListTile(
              key: ValueKey('message_tile_${_message.id}'),
              leading: avatar,
              title: titleWidget,
              subtitle: Text(_message.subject),
              dense: true,
              trailing: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    bool changed = false;
                    if (Platform.isIOS) {
                      changed = await Navigator.of(context, rootNavigator: true)
                          .pushNamed<bool>(TenmokuRouter.messageRoute,
                              arguments: _message);
                    } else {
                      changed = await Navigator.pushNamed<bool>(
                          context, TenmokuRouter.messageRoute,
                          arguments: _message);
                    } // TODO need to find out how to refresh only certain messages w/o redoing the whole list
                    if (changed) {
                      BlocProvider.of<RedditMessagesCubit>(context).refresh();
                    }
                  },
                  child: Icon(
                    Icons.keyboard_arrow_right,
                  ))),
        ),
        Divider(
          height: 0,
        )
      ],
    );
  }
}

/// Takes up the space of the list and informs people they need to login
class UnauthenticatedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Please login to see your messages'),
        CupertinoButton(
          child: const Text('Login'),
          onPressed: () => _authenticate(context),
        )
      ],
    );
  }

  void _authenticate(BuildContext context) {
    BlocProvider.of<RedditClientCubit>(context).authenticate();
  }
}
