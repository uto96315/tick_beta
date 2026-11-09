import 'package:tick/services/gateways.dart';

NotificationCopy notificationCopy(String languageCode) {
  final ja = languageCode == 'ja';
  if (ja) {
    return (
      segmentTitle: '',
      segmentBody: '',
      endTitle: '定時、来た',
      endBody: 'もう帰っていい。たぶん。',
      callTitle: '着信',
      callBody: '{name}',
    );
  }
  return (
    segmentTitle: '',
    segmentBody: '',
    endTitle: "Shift's over",
    endBody: 'You can leave. Probably.',
    callTitle: 'Incoming call',
    callBody: '{name}',
  );
}

/// One line per finished chunk. Avoids dry "3/36 done" progress text.
({String title, String body}) segmentNotification(
  String languageCode,
  int segmentIndex,
  int total,
) {
  final done = segmentIndex + 1;
  final left = total - done;
  final ja = languageCode == 'ja';
  if (total <= 0) {
    return ja
        ? (title: '区切り', body: '1コマ終わった')
        : (title: 'Chunk', body: 'One down');
  }
  final early = done * 3 <= total;
  final late = done * 3 > total * 2;
  if (ja) {
    if (early) {
      return switch (segmentIndex % 3) {
        0 => (title: '1コマだけ進んだ', body: 'あと$leftコマ。まだ昼前だ'),
        1 => (title: 'チッ…終わった', body: 'あと$left。座り心地、悪くない？'),
        _ => (title: '小さな勝利', body: 'ゴールは遠い。でも、動いてはいる'),
      };
    }
    if (late) {
      return switch (segmentIndex % 3) {
        0 => (title: 'あとちょい', body: '残り$leftコマ。出口が見えてきた'),
        1 => (title: 'もうすぐ定時圏内', body: 'あと$left。心の時計が早い'),
        _ => (title: 'ラストスパート（気持ち）', body: '残り$leftコマ。肩、下ろしていい'),
      };
    }
    return switch (segmentIndex % 3) {
      0 => (title: '折り返し超えた', body: '残り$leftコマ。半分よりマシ'),
      1 => (title: '耐えた', body: 'あと$left。今日はまだ続く'),
      _ => (title: '区切りクリア', body: '残り$left。ひと息つこ'),
    };
  }
  if (early) {
    return switch (segmentIndex % 3) {
      0 => (title: 'One chunk down', body: '$left to go. Still morning, sort of.'),
      1 => (title: 'Survived a slice', body: '$left left. Chair still works.'),
      _ => (title: 'Tiny win', body: 'Goal’s far. You moved anyway.'),
    };
  }
  if (late) {
    return switch (segmentIndex % 3) {
      0 => (title: 'Almost there', body: '$left left. Exit sign vibes.'),
      1 => (title: 'Home stretch', body: '$left chunks. Heart clock runs fast.'),
      _ => (title: 'Last push (feelings)', body: '$left left. Shoulders can drop.'),
    };
  }
  return switch (segmentIndex % 3) {
    0 => (title: 'Past halfway', body: '$left left. Better than the first half.'),
    1 => (title: 'Still going', body: '$left chunks. Today continues.'),
    _ => (title: 'Chunk cleared', body: '$left left. Breathe.'),
  };
}

String fill(String template, Map<String, String> values) {
  var result = template;
  for (final entry in values.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value);
  }
  return result;
}
