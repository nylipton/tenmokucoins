import 'package:draw/draw.dart' ;

class RedditClientService {
  final Reddit _reddit ;
  String _username ;
  static const String USER_AGENT = 'tenmokucoins';
  
  RedditClientService( {Reddit redditInstance }) :_reddit = redditInstance ;

  String get authUrl => _reddit.auth.url(['*'], USER_AGENT ).toString() ;
  String get username => _username ;

  factory RedditClientService.createInstalledFlow( ) {
    
    final Reddit reddit = Reddit.createInstalledFlowInstance(
    clientId: 'pZ0Cg23cADUvgQ',
    userAgent: USER_AGENT,
    redirectUri: Uri.parse('https://github.com/nylipton/tenmokucoins') ) ;

    return RedditClientService( redditInstance: reddit ) ;
  }

  Future<void> authorizeClient( String authCode ) async {
    _reddit.auth.url(['*'], USER_AGENT ) ;
    await _reddit.auth.authorize( authCode ) ;

  }

  Future<void> setUsername() async {
    Redditor redditor = await _reddit.user.me();
  }
}