import 'package:tick/services/gateways.dart';

NotificationCopy notificationCopy(String languageCode) {
  final ja = languageCode == 'ja';
  if (ja) {
    return (
      segmentTitle: '区切りクリア',
      segmentBody: '{done}/{total} まで来た',
      endTitle: '自由だー！',
      endBody: '予定の時間になった',
      callTitle: '着信',
      callBody: '{name}',
    );
  }
  return (
    segmentTitle: 'Chunk cleared',
    segmentBody: '{done}/{total} down',
    endTitle: "You're free!",
    endBody: 'The timer is done',
    callTitle: 'Incoming call',
    callBody: '{name}',
  );
}

String fill(String template, Map<String, String> values) {
  var result = template;
  for (final entry in values.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value);
  }
  return result;
}
