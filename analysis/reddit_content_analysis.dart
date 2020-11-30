import 'package:draw/draw.dart';
import 'dart:io';

import 'package:tenmoku_coins/bloc/reddit_oauth_secret.dart';

Future<int> main() async {
  const subredditName = 'pmsforsale'; //+coins4sale';
  print('Connecting to Reddit');
  final reddit = await Reddit.createUntrustedReadOnlyInstance(
      clientId: REDDIT_CLIENT_ID,
      deviceId: 'DO_NOT_TRACK_THIS_DEVICE',
      userAgent: 'readonly-client');

  if (reddit != null) {
    final subredditRef = reddit.subreddit(subredditName);
    await subredditRef
        .newest(limit: 10)
        .forEach((content) => analyzeContent(content));
    print('done analyzing');
    print('Program analyzed $count submissions from reddit');
    print('There are ${wordMap.length} words that were used in posts');

    print('Writing output to file...');
    var sortedKeys = wordMap.keys.toList(growable: false)
      ..sort((k1, k2) => wordMap[k2].compareTo(wordMap[k1]));

    var file = File('reddit_data_analysis.csv');
    if (file.existsSync()) file.deleteSync();

    sortedKeys.forEach((k) =>
        file.writeAsStringSync('$k,${wordMap[k]}\n', mode: FileMode.append));
    print('Data analysis written to ${file.path}');
  } else {
    stderr.write('Couldn\'t get reddit instance');
    return -1 ;
  }
  return 0 ;
}

Map<String, int> wordMap = {};
int count = 0;

void analyzeContent(Submission submission) {
  if (submission != null) {
    submission.selftext
        .toLowerCase()
        .replaceAll(RegExp('[^A-Za-z0-9 ]'), '')
        .split(' ')
        .forEach((word) {
      var w =
          word; //.toLowerCase().replaceAll(RegExp(r"/[^0-9a-zA-Z]/"), "");
      if (w.isNotEmpty) wordMap.containsKey(w) ? wordMap[w]++ : wordMap[w] = 1;
    });
    count++;
    stdout.write('.');
  }
}
