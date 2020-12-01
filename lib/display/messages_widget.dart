import 'package:draw/draw.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/bloc/reddit_client_cubit.dart';
import 'package:tenmoku_coins/bloc/reddit_messages_cubit.dart';

class MessagesWidget extends StatefulWidget {
  final String title;

  MessagesWidget(this.title);

  @override
  _MessagesWidgetState createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {
  final Logger logger = Logger() ;

  // State variables
  var _messages;
  bool _authenticated ;

  _MessagesWidgetState( ) {
    _messages = [];
    _authenticated = false ;
    logger.d( 'Creating new _MessagesWidgetState object' ) ;
  }

  @override
  Widget build(BuildContext context) {
    Widget widget = _authenticated ? Container(child: Center(child: Text( 'You have ${_messages.length} messages'))) : Center(child: UnauthenticatedWidget()) ;
    return BlocListener<RedditMessagesCubit, BaseRedditMessagesState>(
      listener: (BuildContext context, state) {
        setState(() {
          if( state is UnauthenticatedUserState ) {
            _authenticated = false ;
            RedditClientCubit redditCubit = BlocProvider.of(context);
            redditCubit.authenticate();
          } else {
            _authenticated = true ;
            _messages = state.messages;
          }
        });
      },
      child: Center(
          child: widget),
    );
  }
}

class UnauthenticatedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text( 'Please login to see your messages' ),
        CupertinoButton( child: Text( 'Login' ), onPressed: () => _authenticate(context),)
      ],
    ) ;
  }

  void _authenticate( BuildContext context) {
    BlocProvider.of<RedditClientCubit>( context ).authenticate() ;
  }
}
