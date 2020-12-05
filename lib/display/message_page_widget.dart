import 'package:draw/draw.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:io';

import 'DateTimeFormatter.dart';

class MessagePageWidget extends StatelessWidget {
  final Logger logger = Logger();

  final Message message;

  MessagePageWidget(this.message);

  @override
  Widget build(BuildContext context) {
    Widget w;
    if (Platform.isIOS) {
      w = CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          actionsForegroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: _messageList(),
      );
    } else {
      // Material implementation
      w = Scaffold(appBar: AppBar(), body: _messageList());
    }
    return w;
  }

  // TODO mark as read automatically?
  // TODO allow the user to mark this as unread
  // TODO indicate if new
  // TODO indicate if "distinguished" which is a String
  // TODO allow inline images from URL
  // TODO make URLs tappable
  Widget _messageList() {
    int numReplies = 0;
    try {
      numReplies = message.replies.length;
    } catch (e) {
      logger.v('No replies to message');
    }
    logger.d('There are $numReplies replies');
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        Message msg = index == 0 ? message : message.replies[index - 1];
        return ExpansionTile(
          key: ValueKey(msg.id),
          title: RichText(
              text: TextSpan(
            text: msg.author,
            style: DefaultTextStyle.of(context)
                .style
                .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          )),
          subtitle: RichText(
              text: TextSpan(
                  text:
                      'sent ${DateTimeFormatter.dateFormat.format(msg.createdUtc)}',
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                TextSpan(text: ' to '),
                TextSpan(
                  text: msg.destination,
                ),
              ])),
          initiallyExpanded: true,
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
          children: [
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  Text(
                    msg.body,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      itemCount: numReplies + 1,
    );
  }
}
