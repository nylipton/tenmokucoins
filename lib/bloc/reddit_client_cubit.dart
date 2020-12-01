import 'dart:async';
import 'dart:math';

import 'package:draw/draw.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenmoku_coins/bloc/reddit_oauth_secret.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

/// The state of this Cubit is a [RedditWrapper] which holds a [Reddit] instance.
/// The wrapper is because DRAW's [Reddit] doesn't implement equality. <p>
/// Make sure that the state isn't [null] and then check in the Reddit instance
/// to make sure that it's authenticated. This should notify of new state when
/// the user has authenticated.
/// TODO turn this into a Bloc with states like new, untrusted, authenticated
class RedditClientCubit extends Cubit<RedditWrapper> {
  final logger = Logger();
  RedditWrapper _redditWrapper;
  Reddit _tempReddit;

  static const userAgentId = 'tenmokucoins';
  static const authCodeKey = 'reddit_auth_code';

  /// stream of deep-link listener updates, for getting OAuth authorization code
  StreamSubscription _sub;

  RedditClientCubit() : super(RedditWrapper(null)) {
    // First, set up a listener for deep link updates. This is necessary for
    // being notified when the authenticator has been updated.
    _sub = getUriLinksStream().listen((uri) async {
      logger.d('Got an updated response: $uri');
      if (uri != null && uri.queryParameters['code'] != null) {
        var authCode = uri.queryParameters['code'];
        logger.d('Got authorization code $authCode');
        await closeWebView();
        await _tempReddit.auth.authorize(authCode);

        var sharedPrefs = await SharedPreferences.getInstance();
        await sharedPrefs.setString(
            authCodeKey, _tempReddit.auth.credentials.toJson());

        emit(RedditWrapper(
            _tempReddit)); // Create a new RedditWrapper to force state update
      } else {
        logger.i('Got no initial link back from the authorization Uri');
      }
    });

    // Second, set the wrapper to hold an anonymous Reddit instance
    if (state == null || state.reddit == null) {
      logger.d('Initializing Reddit instance with anonymous client');
      Reddit.createUntrustedReadOnlyInstance(
        clientId: REDDIT_CLIENT_ID,
        userAgent: userAgentId,
        deviceId: Uuid().v4(),
      ).then((r) {
        logger.d('Setting the reddit wrapper to an untrusted user');
        emit(RedditWrapper(r));
      });
    }
  }

  /// Instance of RedditWrapper, which may be should be untrusted at first,
  /// then authenticated
  RedditWrapper get redditWrapper => _redditWrapper;

  /// Launches the browser, which allows the user to login.
  void authenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var authCode = prefs.get(authCodeKey);
    if (authCode == null) {
      logger.d(
          'Starting to authenticate by requesting the user to authenticate...');
      try {
        _tempReddit = Reddit.createInstalledFlowInstance(
            redirectUri: Uri.parse("tenmokucoins://tenmoku.com"),
            clientId: REDDIT_CLIENT_ID,
            userAgent: userAgentId);

        final authUrl = _tempReddit.auth.url(
            ['read', 'account', 'identity', 'privatemessages'], 'tenmokucoins-auth',
            compactLogin: true);
        logger.d("authentication URL is $authUrl");

        if (await canLaunch(authUrl.toString())) {
          logger.d("launching authorization page");
          await launch(authUrl.toString());
        } else {
          logger.w('Not able to launch browser to authenticate');
          addError('Not able to launch browser to authenticate');
        }
      } catch (e, stacktrace) {
        addError(e);
        logger.e(e, stacktrace);
      }
    } else {
      logger.d('Starting to reauthenticate using the stored credentials');
      _tempReddit = Reddit.restoreInstalledAuthenticatedInstance(authCode,
          userAgent: userAgentId,
          clientId: REDDIT_CLIENT_ID,
          redirectUri: Uri.parse("tenmokucoins://tenmoku.com"));
      if (_tempReddit != null && _tempReddit.auth.isValid) {
        var me = await _tempReddit.user.me ;
        logger.d(
            'Successfully reauthenticated using stored credentials. User ${me}');
        emit(RedditWrapper(_tempReddit));
      } else {
        logger.e(
            'Unable to reauthenticate using stored credentials. Clearing the stored one');
        await prefs.setString(authCodeKey, null);
        authenticate() ; // try this again
      }
    }
  }

  void dispose() {
    _sub.cancel();
    super.close();
  }
}

/// a wrapper around the DRAW Reddit class which makes adds equatable functionality for the Cubit
class RedditWrapper extends Equatable {
  final Reddit reddit;
  final int id; //used to force identification as new since Reddit doesn't

  RedditWrapper(this.reddit) : id = Random().nextInt(10000);

  /// gets a human-readable username with 'not logged in' if the user isn't
  /// authenticated
  Future<String> getUsername() {
    var username = (reddit == null || !reddit.auth.isValid)
        ? Future<String>.value('not logged in')
        : reddit.user
            .me()
            .then((r) => r.displayName)
            .catchError((err) => 'Anonymous');
    return username;
  }

  @override
  List<Object> get props => [reddit, reddit?.auth?.isValid, id];

  @override
  bool get stringify => true;

  /// whether the [Reddit] instance is [null] or read-only
  bool isAuthenticated() => !(reddit == null || reddit.readOnly);
}
