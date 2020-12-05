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
  final String title;

  MessagesWidget(this.title);

  @override
  _MessagesWidgetState createState() => _MessagesWidgetState();
}

final Logger logger = Logger();

class _MessagesWidgetState extends State<MessagesWidget> {
  // State variables
  List<Message> _messages;
  bool _authenticated;

  _MessagesWidgetState() {
    _messages = [];
    _authenticated = false;
    logger.v('Creating new _MessagesWidgetState object');
  }

  @override
  Widget build(BuildContext context) {
    Widget widget = _authenticated
        ? _messagesWidget()
        : Center(child: UnauthenticatedWidget());
    return BlocListener<RedditMessagesCubit, BaseRedditMessagesState>(
      listener: (BuildContext context, state) {
        setState(() {
          if (state is UnauthenticatedUserState) {
            _authenticated = false;
            RedditClientCubit redditCubit = BlocProvider.of(context);
            redditCubit.authenticate();
          } else {
            _authenticated = true;
            _messages = state.messages;
            _messages.sort((m1, m2) => m2.createdUtc.compareTo(m1.createdUtc));
          }
        });
      },
      child: widget,
    );
  }

  Widget _messagesWidget() {
    return CustomScrollView(
      slivers: [
        _navbar(context),
        if (Platform.isIOS) _iOSRefresh(context),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) {
              return MessageTile(_messages[index]);
            },
            childCount: _messages.length,
          ),
        )
      ],
      shrinkWrap: true,
    );
  }

  Widget _iOSRefresh(BuildContext context) {
    return CupertinoSliverRefreshControl(
        onRefresh: () => Future<void>(
            () => BlocProvider.of<RedditMessagesCubit>(context).refresh()));
  }

  Widget _navbar(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSliverNavigationBar(
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary, // TODO See if this can be removed on iOS
          largeTitle: Text('Messages'),
          trailing: Material(
              color: Theme.of(context).colorScheme.primary,
              child: _newCupertinoMessageIconButton()));
    } else {
      return SliverAppBar(
        elevation: 1.0,
        title: Text(
          widget.title,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        pinned: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.plus_one_outlined),
            tooltip: 'New Message',
            onPressed: () => _composeMessage(context),
          ), /*
          PopupMenuButton<String>(
            onSelected: _overflowMenuAction,
            itemBuilder: (_) {
              var redditWrapper =
                  BlocProvider
                      .of<RedditClientCubit>(context)
                      .state;
              Widget accountField;
              accountField = (redditWrapper.isAuthenticated())
                  ? FutureBuilder(
                  future: redditWrapper.getUsername(),
                  initialData: 'Reddit account: loading',
                  builder: (_, AsyncSnapshot<String> data) {
                    return data.hasData
                        ? Text(data.data)
                        : Text('Loading Reddit account');
                  })
                  : Text('Login to Reddit');
              return <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                  value: overflowMenu[0],
                  child: accountField,
                  enabled: !redditWrapper.isAuthenticated(),
                ),
                PopupMenuItem<String>(
                    value: overflowMenu[1], child: Text(overflowMenu[1]))
              ];*/
          // },
          // )
        ],
      );
    }
  }

  void _composeMessage(BuildContext context) {}

  Widget _newCupertinoMessageIconButton() {
    return IconButton(
        icon: const Icon(
          CupertinoIcons.pencil_circle_fill,
        ),
        onPressed: () {},
        color: Theme.of(context).colorScheme.onPrimary);
  }
}

/// Represents an individual message
class MessageTile extends StatelessWidget {
  final Message message;

  MessageTile(this.message);

  @override
  Widget build(BuildContext context) {
    int replies = 0;
    List<InlineSpan> firstlineChildren = [];
    try {
      replies = message.replies.length;
      if (replies > 0) {
        firstlineChildren = [
          TextSpan(
              text: '  (${replies.toString()})',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100)),
        ];
      }
    } catch (e) {
      logger.v('no replies to message');
    }
    Widget titleWidget = Row(children: [
      RichText(
        text: TextSpan(
            text: message.author,
            style: DefaultTextStyle.of(context)
                .style
                .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            children: firstlineChildren),
      ),
      Expanded(child: Container(),),
      Text( DateTimeFormatter.dateFormat.format(message.createdUtc))
    ]);

    return Column(
      children: [
        Material(
          child: ListTile(
              title: titleWidget,
              subtitle: RichText(
                  text: TextSpan(
                text: message.subject,
                style: DefaultTextStyle.of(context).style,
              )),
              dense: true,
              trailing: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pushNamed(
                      context, TenmokuRouter.messageRoute,
                      arguments: message),
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
