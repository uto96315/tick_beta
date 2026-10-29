// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ozio';

  @override
  String get tagline => 'A timer for people who\'d rather not';

  @override
  String get home => 'Home';

  @override
  String get timer => 'Timer';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get start => 'Start';

  @override
  String get endTimeMode => 'End time';

  @override
  String get durationMode => 'Duration';

  @override
  String get interval => 'Chunk';

  @override
  String get custom => 'Custom';

  @override
  String get useShift => 'Use today\'s shift';

  @override
  String get remaining => 'Left';

  @override
  String get chunks => 'Chunks';

  @override
  String get freeTitle => 'You\'re free!';

  @override
  String get freeBody => 'That\'s the day. Go do something that isn\'t work.';

  @override
  String get goHome => 'Home';

  @override
  String get seeHistory => 'See history';

  @override
  String get extend => 'Extend';

  @override
  String get endEarly => 'Stop here';

  @override
  String get earlyDone => 'Stopping here.';

  @override
  String get noSession => 'Nothing running yet.';

  @override
  String get breaksKeepGoing => 'Breaks keep counting. The end time stays put.';

  @override
  String get noPause => 'There\'s no pause. It just keeps going.';

  @override
  String get notifyTitle => 'Notifications';

  @override
  String get notifyChunk => 'Chunk complete';

  @override
  String get notifyEnd => 'Timer finished';

  @override
  String get sound => 'Sound';

  @override
  String get vibration => 'Haptics';

  @override
  String get vibrationHelp =>
      'Haptics play while Ozio is open. Notification vibration follows the iPhone mute switch.';

  @override
  String get endAction => 'When it ends';

  @override
  String get actionCelebration => 'Freedom screen';

  @override
  String get actionHome => 'Go home';

  @override
  String get actionHistory => 'Open history';

  @override
  String get visual => 'Timer look';

  @override
  String get visualHelp => 'These are prototypes. Switch them and compare.';

  @override
  String get visualTiles => 'Tiles';

  @override
  String get visualMap => 'Stage map';

  @override
  String get visualCharacter => 'Character';

  @override
  String get visualGauge => 'Gauge';

  @override
  String get showCharacter => 'Show character';

  @override
  String get autoStart => 'Start at the scheduled time';

  @override
  String get autoStartHelp =>
      'Starts on its own only while Ozio is open. If the app was closed, it asks next time you open it.';

  @override
  String get schedule => 'Work schedule';

  @override
  String get account => 'Account';

  @override
  String get premium => 'Premium';

  @override
  String get camouflage => 'Camouflage';

  @override
  String get fakeCall => 'Fake call';

  @override
  String get trigger => 'How to switch back';

  @override
  String get triggerCorner => 'Tap the top right';

  @override
  String get triggerLong => 'Long press';

  @override
  String get triggerSwipe => 'Swipe down';

  @override
  String get camouflageHint =>
      'A static screen inside Ozio. It does not pretend to be the iPhone Home Screen.';

  @override
  String get backHintCorner => 'Tap the top right to go back';

  @override
  String get backHintLong => 'Long press to go back';

  @override
  String get backHintSwipe => 'Swipe down to go back';

  @override
  String get callNow => 'Call now';

  @override
  String get callLater => 'Schedule';

  @override
  String get callers => 'Callers';

  @override
  String get weeklyLimit => 'Free: once a week';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get weekReset => 'The free call resets every Monday.';

  @override
  String get answer => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get mute => 'Mute';

  @override
  String get endCall => 'End';

  @override
  String get incoming => 'Incoming';

  @override
  String get mobile => 'mobile';

  @override
  String get startPromptTitle => 'Start this shift?';

  @override
  String get startNow => 'Start';

  @override
  String get notToday => 'Not today';

  @override
  String get patterns => 'Patterns';

  @override
  String get weekdays => 'Week';

  @override
  String get holiday => 'Day off';

  @override
  String get customDay => 'Different hours';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get name => 'Name';

  @override
  String get startTime => 'Start';

  @override
  String get endTime => 'End';

  @override
  String get offDay => 'Off';

  @override
  String get breakLabel => 'Break';

  @override
  String get addBreak => 'Add a break';

  @override
  String get noBreaks => 'No breaks';

  @override
  String get overtime => 'Overtime';

  @override
  String get overtimeNone => 'None';

  @override
  String get memo => 'Note';

  @override
  String get memoHint => 'One line, if you want';

  @override
  String get computedNote =>
      'Overtime and total break time are calculated. They aren\'t stored twice.';

  @override
  String get statusDone => 'Finished';

  @override
  String get statusEarly => 'Stopped early';

  @override
  String get extensions => 'Extensions';

  @override
  String get originalEnd => 'Original end';

  @override
  String get actualStart => 'Actual start';

  @override
  String get actualEnd => 'Actual end';

  @override
  String get achievement => 'Done';

  @override
  String get anonymous => 'Using Ozio anonymously';

  @override
  String get registerEmail => 'Keep this data with email';

  @override
  String get registerGoogle => 'Keep this data with Google';

  @override
  String get signInEmail => 'Sign in with email';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This deletes the account and its settings and history.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get firebaseLocal =>
      'Saved on this iPhone. Sign-in needs the Firebase project.';

  @override
  String get premiumPitch =>
      'A one-time purchase. Unlimited fake calls, your own callers, camouflage screens, ringtones, and more ways for the chick to talk.';

  @override
  String get premiumOwned => 'Premium is on';

  @override
  String get buy => 'Buy';

  @override
  String get restore => 'Restore purchase';

  @override
  String get priceFallback => '¥500';

  @override
  String get freeTier => 'Free';

  @override
  String get languageFollows => 'Language follows the iPhone setting.';

  @override
  String get customMinutes => 'Chunk length in minutes';

  @override
  String get customExtend => 'Minutes to add';

  @override
  String get invalidMinutes => 'Enter at least 1 minute';

  @override
  String get tooShort => 'The end has to be at least a minute away';

  @override
  String get limitReached => 'You\'ve used this week\'s free call';

  @override
  String get premiumRequired => 'That\'s a Premium extra';

  @override
  String get encourage1 =>
      'A little further. You\'ve already done the hard part of starting.';

  @override
  String get encourage2 => 'Still here. That\'s the whole trick.';

  @override
  String get encourage3 => 'Future you is grateful. Present you can grumble.';

  @override
  String get encourage4 => 'One more chunk. Then the door.';

  @override
  String get encourage5 => 'You\'re allowed to be tired and still finish.';

  @override
  String get burstOne => 'Chunk cleared!';

  @override
  String get burstMany => 'Chunks cleared!';

  @override
  String get addCaller => 'Add a caller';

  @override
  String get callerName => 'Caller name';

  @override
  String get photo => 'Photo';

  @override
  String get emptyHistory => 'No days saved yet.';

  @override
  String get running => 'In progress';

  @override
  String get applyShift => 'Count from the scheduled start';

  @override
  String get upcomingAuto => 'Will start on its own at the scheduled time';

  @override
  String get hours => 'Hours';

  @override
  String get mins => 'Min';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get authUnavailable => 'That sign-in isn\'t available yet';

  @override
  String get authInvalid => 'Check the email address';

  @override
  String get authWeak => 'Use at least 6 characters';

  @override
  String get authExists => 'That email is already registered. Sign in instead.';

  @override
  String get authWrong => 'Email or password didn\'t match';

  @override
  String get authRecent => 'Sign in again, then delete the account';

  @override
  String get authCanceled => 'Canceled';

  @override
  String get authUnknown => 'Couldn\'t finish that';

  @override
  String get purchaseUnavailable => 'The App Store purchase isn\'t available';

  @override
  String get offline => 'Offline. Ozio keeps going and will sync later.';

  @override
  String get nextDay => 'Next day';

  @override
  String get newPattern => 'New pattern';

  @override
  String get editPattern => 'Edit pattern';

  @override
  String get continueTimer => 'Open timer';

  @override
  String get passwordHint => '6 or more characters';

  @override
  String get linkKeeps =>
      'Registering keeps the history and settings you already have.';

  @override
  String get anonymousLoss =>
      'An anonymous reinstall does not bring the data back. A registered account does.';

  @override
  String get switchHelp =>
      'Signing in to another account shows that account\'s data on this iPhone.';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get stage => 'Stage';

  @override
  String get muted => 'Muted';

  @override
  String get inCall => 'Calling';

  @override
  String get noShiftNeeded => 'You can use the timer with no schedule.';

  @override
  String get intervalHelp =>
      'The last chunk shrinks to fit whatever time is left.';

  @override
  String get close => 'Close';

  @override
  String get requiredName => 'Add a name';

  @override
  String get scheduledCall => 'Call scheduled';

  @override
  String get cancelCall => 'Cancel this call';

  @override
  String get googleMissing =>
      'Google sign-in needs a CLIENT_ID in GoogleService-Info.plist.';

  @override
  String get crossesMidnight => 'This shift runs past midnight';

  @override
  String get breakTotal => 'Break total';

  @override
  String get status => 'Status';

  @override
  String get rate => 'Rate';

  @override
  String get extendTotal => 'Extended';

  @override
  String get pickEnd => 'Choose the end';

  @override
  String get earlyBy => 'Finished before the plan';

  @override
  String get localAccount => 'This iPhone only';

  @override
  String get registered => 'Signed in';

  @override
  String get overrides => 'Special days';

  @override
  String get addOverride => 'Add a day';

  @override
  String get deletePattern => 'Delete pattern';

  @override
  String get premiumCamouflage => 'Long press and swipe are Premium';

  @override
  String get premiumCallers => 'Custom callers are Premium';

  @override
  String get usedThisWeek => 'Used this week';

  @override
  String get ringing => 'ringing';

  @override
  String get notRunning => 'Not started';

  @override
  String get startTimer => 'Start the timer';

  @override
  String get chunksAhead => 'Left';

  @override
  String get todayProgress => 'Today';

  @override
  String get plannedEnd => 'Ends';

  @override
  String get extendChoose => 'How much longer?';

  @override
  String get keepGoing => 'A little longer. You can do it.';

  @override
  String get historyWork => 'Work history';

  @override
  String get viewList => 'List';

  @override
  String get viewCalendar => 'Calendar';

  @override
  String get minuteChunk => ' min chunks';

  @override
  String get hourChunk => ' hour chunks';

  @override
  String get intervalCustom => 'Custom';

  @override
  String get nowChunk => 'Now';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialStart => 'Start';

  @override
  String get tutorial1Title => 'Split the time until you\'re done';

  @override
  String get tutorial1Body =>
      'Pick an end time and Ozio breaks the stretch into small chunks.';

  @override
  String get tutorial2Title => 'How long each chunk is';

  @override
  String get tutorial2Body =>
      'On the home screen, choose 15 min, 30 min, 1 hour, or your own length.';

  @override
  String get tutorial3Title => 'Where you are right now';

  @override
  String get tutorial3Body =>
      'The timer shows the current chunk, like Now 4:10–4:30.';

  @override
  String get updateRequiredTitle => 'Please update';

  @override
  String get updateRequiredBody => 'This version can\'t continue.';

  @override
  String get updateAvailableTitle => 'A newer version is out';

  @override
  String get updateAvailableBody => 'You can keep using this one.';

  @override
  String get updateAction => 'Update';

  @override
  String get updateLater => 'Later';

  @override
  String get chickNormal1 => 'Starting is the hard part.';

  @override
  String get chickNormal2 => 'You can stay lazy. The chunks still shrink.';

  @override
  String get chickNormal3 => 'Small pieces, until the day ends.';

  @override
  String get chickTired1 => 'Still a long way. This chunk will end, though.';

  @override
  String get chickTired2 => 'You don\'t need motivation. Time runs out first.';

  @override
  String get chickTired3 => 'Sitting here still counts as progress.';

  @override
  String get chickHappy1 => 'A little further. This pace is fine.';

  @override
  String get chickHappy2 => 'Not bad. The number is actually going down.';

  @override
  String get chickHappy3 => 'Finish this chunk, and one more is gone.';

  @override
  String get chickCheer1 => 'Halfway\'s gone. The view changed.';

  @override
  String get chickCheer2 => 'From here, time does the work.';

  @override
  String get chickCheer3 => 'That\'s something. I mean it.';

  @override
  String get chickAttention1 => 'Almost there. The door is in sight.';

  @override
  String get chickAttention2 => 'Nearly done. You can stop trying so hard.';

  @override
  String get chickAttention3 => 'Past this chunk, today is mostly over.';

  @override
  String get chickSurprise1 => 'The end time passed. You\'re still here.';

  @override
  String get chickSurprise2 => 'Leaving time already arrived.';

  @override
  String get chickSurprise3 => 'Overtime, then. The chunks still shrink.';

  @override
  String get chickSleep1 => 'Break. Nothing is required here.';

  @override
  String get chickSleep2 => 'You can close your eyes for this one.';

  @override
  String get chickSleep3 => 'Stay like this until the break ends.';

  @override
  String get chickDone1 => 'Today\'s part is over.';

  @override
  String get chickDone2 => 'You sat through it. Work can stop now.';

  @override
  String get chickDone3 => 'You\'re free. You can leave.';

  @override
  String get chickBack1 => 'The timer is moving. Pick up when you\'re back.';

  @override
  String get chickBack2 => 'Step away. The chunks keep shrinking.';

  @override
  String get chickBack3 => 'I\'ll keep it moving. No need to rush back.';

  @override
  String get chickNotice1 => 'One chunk is done. On to the next.';

  @override
  String get chickNotice2 => 'It\'s getting smaller. You can see it.';

  @override
  String get chickNotice3 => 'One finished. That\'s enough.';

  @override
  String get chickGoodjob1 => 'A few are done. Not amazing. Still real.';

  @override
  String get chickGoodjob2 => 'Further along than it feels.';

  @override
  String get chickGoodjob3 => 'Stay seated. Another one will go.';

  @override
  String get chickLove1 => 'Today can stop here.';

  @override
  String get chickLove2 => 'You finished it. That counts.';

  @override
  String get chickLove3 => 'You can drop the work face now.';

  @override
  String get lookHome => 'Home';

  @override
  String get lookNotes => 'Notes';

  @override
  String get lookCalendar => 'Calendar';

  @override
  String get premiumLooks => 'Notes and Calendar are Premium';

  @override
  String get chickVoiceTitle => 'How the chick talks';

  @override
  String get voicePlain => 'Plain';

  @override
  String get voiceLazy => 'Even lazier';

  @override
  String get voiceKansai => 'Kansai';

  @override
  String get voiceCustom => 'Your line';

  @override
  String get premiumVoice => 'Extra voices are Premium';

  @override
  String get customLine => 'One line for the chick';

  @override
  String get moodHeavy => 'Heavy';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodSleepy => 'Sleepy';

  @override
  String get moodCall => 'Call in this mood';

  @override
  String get premiumMoodCall => 'The call after a mood is Premium';

  @override
  String get soundClassic => 'Classic';

  @override
  String get soundSoft => 'Soft';

  @override
  String get soundBright => 'Bright';

  @override
  String get premiumSounds => 'Changing the ringtone is Premium';

  @override
  String get callBeforeEnd => '10 min before the end';

  @override
  String get beforeEndPassed => 'That time has passed';

  @override
  String get noteMilk => 'Milk and eggs';

  @override
  String get noteDentist => 'Dentist, next week';

  @override
  String get noteReturn => 'Return the book';

  @override
  String get noteMilkBody => 'Buy them on the way home.';

  @override
  String get noteDentistBody => 'Afternoon. No work talk.';

  @override
  String get noteReturnBody => 'The due date is close.';

  @override
  String get calLunch => 'Lunch';

  @override
  String get voiceLazy1 => 'Ugh. Heavy.';

  @override
  String get voiceLazy2 => 'Don\'t want to move. Time still shrinks.';

  @override
  String get voiceLazy3 => 'Today can be like this.';

  @override
  String get voiceLazy4 => 'Motivation is tomorrow\'s problem.';

  @override
  String get voiceLazy5 => 'Sitting here is the job.';

  @override
  String get voiceLazy6 => 'One more chunk. Probably.';

  @override
  String get voiceKansai1 => 'Still a long way, huh.';

  @override
  String get voiceKansai2 => 'It\'s coming along.';

  @override
  String get voiceKansai3 => 'We\'ll take it easy.';

  @override
  String get voiceKansai4 => 'A bit more until the end.';

  @override
  String get voiceKansai5 => 'Nice. Nice.';

  @override
  String get voiceKansai6 => 'You could just go home.';

  @override
  String get moodHeavy1 => 'Heavy. I know.';

  @override
  String get moodHeavy2 => 'You can stay like that. It\'s moving.';

  @override
  String get moodHeavy3 => 'Today can be a heavy one.';

  @override
  String get moodTired1 => 'Tired.';

  @override
  String get moodTired2 => 'You got this far.';

  @override
  String get moodTired3 => 'Rest. Time keeps going.';

  @override
  String get moodSleepy1 => 'Sleepy.';

  @override
  String get moodSleepy2 => 'Half-open eyes are enough.';

  @override
  String get moodSleepy3 => 'Doze if you want.';

  @override
  String get slack => 'Step away';

  @override
  String get slackIntro =>
      'This is for leaving your seat. It shows a work call, or swaps this app for another screen. Nobody is actually called.';

  @override
  String get slackCall => 'Pretend a call came in';

  @override
  String get slackHide => 'Swap the screen';

  @override
  String get slackWeekly => 'The free call is once a week.';

  @override
  String get slackMore => 'Get more calls';
}
