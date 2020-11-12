import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';

class SubredditCubit extends Cubit<List<SubmissionItem>> {
  Map<String,Stream<UserContent>> _redditStreamMap ={};

  SubredditCubit() : super([]);

  /// Sets the Reddit content stream that this will listen to in order
  /// to update the content.
  void setStream( String subreddit, Stream<UserContent> contentStream ) {
    this._redditStreamMap[subreddit] = contentStream ;
    contentStream.listen( _process ) ;
  }

  /// listen function for Reddit content
  void _process(UserContent event) {
    // print( 'Got new content ' ) ;
    state.add( SubmissionItem(event) ) ;
    emit( state ) ;
  }
}

class SubmissionItem extends Equatable {

  final Submission _submission ;
  SubmissionItem( this._submission ) ;

  String getTitle() => _submission.title ;

  @override
  // TODO: implement props
  List<Object> get props => [_submission.title,_submission.id];

  @override
  bool get stringify => true ;


}
