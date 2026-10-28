// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tick';

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
      'Haptics play while Tick is open. Notification vibration follows the iPhone mute switch.';

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
      'Starts on its own only while Tick is open. If the app was closed, it asks next time you open it.';

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
      'A static screen inside Tick. It does not pretend to be the iPhone Home Screen.';

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
  String get anonymous => 'Using Tick anonymously';

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
      'A one-time purchase. Unlimited fake calls, your own callers, and more ways to leave camouflage.';

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
  String get offline => 'Offline. Tick keeps going and will sync later.';

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
}
