import 'dart:async';
import 'dart:math';

import 'package:draw/draw.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tenmoku_coins/bloc/reddit_oauth.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

/// The state of this Cubit is a [RedditWrapper] which holds a [Reddit] instance.
/// The wrapper is because DRAW's [Reddit] doesn't implement equality. <p>
/// Make sure that the state isn't [null] and then check in the Reddit instance to make sure
/// that it's authenticated. This should notify of new state when the user has authenticated.
/// TODO implement restoring authentication
class RedditClientCubit extends Cubit<RedditWrapper> {
  RedditWrapper _redditWrapper;
  String userAgentId = 'tenmokucoins';

  /// stream of deep link listener updates
  StreamSubscription _sub;

  RedditClientCubit() : super(RedditWrapper(null)) {
    // First, set up a listener for deep link updates. This is necessary for
    // being notified when the authenticator has been updated.
    _sub = getUriLinksStream().listen((uri) async {
      print("Got an updated response: $uri");
      if (uri != null && uri.queryParameters["code"] != null) {
        String authCode = uri.queryParameters["code"];
        print('Got authorization code $authCode');
        await closeWebView();
        // if (_redditWrapper != null && !_redditWrapper.reddit.auth.isValid) {
        await state.reddit.auth.authorize(authCode);
        emit(RedditWrapper(
            state.reddit)); // Create a new RedditWrapper to force state update
        // }
      } else {
        print('Got no initial link back from the authorization Uri');
      }
    });

    // Second, set the wrapper to hold an anonymous Reddit instance
    if (state == null || state.reddit == null) {
      print('Initializing Reddit instance with anonymous client');
      Reddit.createUntrustedReadOnlyInstance(
        clientId: REDDIT_CLIENT_ID,
        userAgent: userAgentId,
        deviceId: Uuid().v4(),
      ).then((r) {
        print('Setting the reddit wrapper to an untrusted user');
        emit(RedditWrapper(r));
      });
    }
  }

  /// Instance of RedditWrapper, which may be should be untrusted at first, then authenticated.
  RedditWrapper get redditWrapper => _redditWrapper;

  /// Launches the browser, which allows the user to login.
  void authenticate() async {
    try {
      print('Starting to authenticate...');
      Reddit reddit = Reddit.createInstalledFlowInstance(
          redirectUri: Uri.parse("tenmokucoins://tenmoku.com"),
          clientId: REDDIT_CLIENT_ID,
          userAgent: userAgentId);

      final authUrl = reddit.auth.url(
          ['read', 'account', 'identity'], 'tenmokucoins-auth',
          compactLogin: true);
      print("authentication URL is $authUrl");
      emit(RedditWrapper(reddit));
      if (await canLaunch(authUrl.toString())) {
        print("launching authorization page");
        launch(authUrl.toString());
      } else {
        print('Not able to launch browser to authenticate');
        addError('Not able to launch browser to authenticate');
      }
    } catch (e, stacktrace) {
      addError(e);
      print(e);
      print(stacktrace);
    }
  }

  void dispose() {
    _sub.cancel();
    super.close();
  }
}

/// a wrapper around the DRAW Reddit class which makes adds equatable functionality for the Cubit
class RedditWrapper extends Equatable {
  final Reddit _reddit;
  final int id; //used to force identification as new since Reddit doesn't

  RedditWrapper(this._reddit) : id = Random().nextInt(10000);

  Future<String> getUsername() {
    if (_reddit == null || !_reddit.auth.isValid)
      return Future<String>.value("not logged in");
    else
      return _reddit.user
          .me()
          .then((r) => r.displayName)
          .catchError((err) => "Anonymous");
  }

  @override
// TODO: implement props
  List<Object> get props => [_reddit, _reddit?.auth?.isValid, id];

  /// use this to get the actual Reddit instance
  Reddit get reddit => _reddit;

  @override
  bool get stringify => true;

  bool isAuthenticated( ) => !( reddit == null || reddit.readOnly ) ;
}
