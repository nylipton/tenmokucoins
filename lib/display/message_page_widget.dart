import 'package:draw/draw.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:io';

import 'DateTimeFormatter.dart';

class MessagePageWidget extends StatelessWidget {
  final Logger logger = Logger();

  final Message _message;

  MessagePageWidget(this._message) {
    _message.markRead();
  }

  @override
  Widget build(BuildContext context) {
    Widget w;

    if (Platform.isIOS) {
      w = CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          transitionBetweenRoutes: false,
          heroTag: 'message_page',
          backgroundColor: Theme.of(context).colorScheme.primary,
          actionsForegroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: _messageList(),
      );
    } else {
      // Material implementation
      w = Scaffold(appBar: AppBar(), body: _messageList());
    }
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: w,
    );
  }

  // TODO allow the user to mark this as unread
  // TODO indicate if "distinguished" which is a String
  // TODO allow inline images from URL
  // TODO make URLs tappable
  Widget _messageList() {
    int numReplies = 0;
    try {
      numReplies = _message.replies.length;
    } catch (e) {
      logger.v('No replies to message');
    }
    logger.d('There are $numReplies replies');
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        if (index < numReplies + 1) {
          Message msg = index == 0 ? _message : _message.replies[index - 1];
          return Material(
            child: ExpansionTile(
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
            ),
          );
        } else {
          // command row
          if (Platform.isIOS) {
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CupertinoButton(
                    onPressed: () {},
                    child: Text('Reply'),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CupertinoButton(
                    onPressed: () {
                      _deleteMessage(_message, context);
                    },
                    child: Text('Delete'),
                  ),
                )
              ],
            );
          } else {
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    label: Text('Reply'),
                    icon: Icon(Icons.reply_sharp),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _deleteMessage(_message, context);
                    },
                    label: Text('Delete'),
                    icon: Icon(Icons.delete),
                  ),
                )
              ],
            );
          }
        }
      },
      itemCount: numReplies + 2,
    );
  }

  void _deleteMessage(Message message, BuildContext context) async {
    if (Platform.isIOS) {
      bool deleted = await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Delete?'),
            content: Text('Do you want to delete this message?'),
            actions: [
              CupertinoDialogAction(
                child: CupertinoButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(false);
                    },
                    child: Text(
                      'Cancel',
                    )),
              ),
              CupertinoDialogAction(
                child: CupertinoButton(
                    onPressed: () {
                      _message.remove();
                      Navigator.of(context, rootNavigator: true).pop(true);
                    },
                    child: Text(
                      'Delete',
                    )),
              ),
            ],
          );
        },
      );
      if (deleted) {
        Navigator.of(context, rootNavigator: true).pop(true);
      }
    } else {
      bool deleted = await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text('Delete?'),
              content: Text('Do you want to delete this message?'),
              actions: [
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                FlatButton(
                  child: Text('Delete'),
                  onPressed: () {
                    _message.remove();
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          });
      if (deleted) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
