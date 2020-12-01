part of 'reddit_messages_cubit.dart';

abstract class BaseRedditMessagesState extends Equatable {
  final List<Message> _messages ;
  
  const BaseRedditMessagesState(this._messages);

  @override
  List<Object> get props => _messages;

  List<Message> get messages => _messages ;
}

class UnauthenticatedUserState extends BaseRedditMessagesState {
  UnauthenticatedUserState(): super([]) ;
}

class UpdatedRedditMessagesState extends BaseRedditMessagesState {
  UpdatedRedditMessagesState(List<Message> messages) : super(messages);

  /// Constructs a new state by tacking on a new message to the old list (note
  /// that it does this by copying the old messages list).
  static BaseRedditMessagesState constructWithNewMessage( {@required BaseRedditMessagesState oldState, @required Message message} ) {
    var newList = [...oldState.messages,message] ;
    return UpdatedRedditMessagesState(newList) ;
  }
}
