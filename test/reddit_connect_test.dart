import 'package:draw/draw.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenmoku_coins/bloc/reddit_oauth.dart';

const userAgentId = 'tenmokucoins';

void main() {
  test('Connect unauthenticated user to Reddit API', () => _connectToReddit);
}

void _connectToReddit() async {
  final reddit = await Reddit.createUntrustedReadOnlyInstance(
      clientId: REDDIT_CLIENT_ID,
      deviceId: 'DO_NOT_TRACK_THIS_DEVICE',
      userAgent: 'readonly-client');

  expect(reddit.readOnly, isTrue);
  expect(await reddit.front.hot().first, isNotNull);

  reddit.subreddit( 'pmsforsale+coins4sale' ).top( ).listen(
      expectAsync1(
          ( content ) {
            print( ( content as Submission ).title ) ;
            expect( content, isNotNull ) ;
          }
      )
  ) ;
}
