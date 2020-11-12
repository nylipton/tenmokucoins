import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';

class SubredditCubit extends Cubit<List<UserContent>> {
  Stream<UserContent> _redditStream ;

  SubredditCubit() : super([]);

  /// Sets the Reddit content stream that this will listen to in order
  /// to update the content.
  void setStream( Stream<UserContent> contentStream ) {
    this._redditStream = contentStream ;
    _redditStream.listen( _process ) ;
  }

  /// listen function for Reddit content
  void _process(UserContent event) {
    print( 'Got new content ' ) ;
    state.add( event ) ;
    emit( state ) ;
  }
}
