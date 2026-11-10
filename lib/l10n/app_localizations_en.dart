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
  String get premium => 'Member status';

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
      'Makes it harder to tell this app is open. Tap the top right to come back.';

  @override
  String get camouflageSetup => 'Set up';

  @override
  String get camouflagePreview => 'Preview';

  @override
  String get camouflageSettingsLead =>
      'Pick a look and register your camouflage image here.';

  @override
  String get camouflageImageUseNote =>
      'Your image is used full screen when the Home look is selected.';

  @override
  String get homeShotTitle => 'Your home screen (Premium)';

  @override
  String get backHintCorner => 'Top right: go back. Top left: register image.';

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
  String get incomingSendMessage => 'Send Message';

  @override
  String get incomingVoicemail => 'Voicemail';

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
  String get registerEmail => 'Sign up';

  @override
  String get registerGoogle => 'Sign up with Google';

  @override
  String get signInEmail => 'Sign in';

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
      'One-time purchase: unlimited fake calls, custom callers, ringtones, camouflage, and an auto call before shift end.';

  @override
  String get registerAccount => 'Account';

  @override
  String get registerAccountHelp => '';

  @override
  String get premiumOfferTitle => 'Your exit plan';

  @override
  String get premiumOfferLead =>
      'One purchase. No weekly call cap, believable incoming screens, and camouflage when someone is watching.';

  @override
  String get premiumOfferCalls => 'Unlimited fake calls';

  @override
  String get premiumOfferCallsNote =>
      'Say \"I can\'t talk right now\" the moment you need it';

  @override
  String get premiumOfferCallers => 'Custom callers';

  @override
  String get premiumOfferCallersNote =>
      'Names and photos for your boss, client, or whoever fits';

  @override
  String get premiumOfferIncoming => 'iPhone-style incoming screen';

  @override
  String get premiumOfferIncomingNote =>
      'Decline and answer buttons that look like the real thing';

  @override
  String get premiumOfferSounds => 'Pick a ringtone';

  @override
  String get premiumOfferSoundsNote => 'Sounds like a real phone in the room';

  @override
  String get premiumOfferLooks => 'Camouflage screens';

  @override
  String get premiumOfferLooksNote =>
      'Notes, calendar, or your own home-screen screenshot';

  @override
  String get premiumOfferVoice => 'More ways for the chick to talk';

  @override
  String get premiumOfferBefore => 'Auto call before shift end';

  @override
  String get premiumOfferBeforeNote =>
      'Ring ten minutes before you\'re done for the day';

  @override
  String get premiumOfferLater => 'Not now';

  @override
  String premiumOfferBuy(String price) {
    return 'Unlock for $price';
  }

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
  String get idleAfterShiftStatus => 'Past scheduled end';

  @override
  String get idleAfterShiftBody =>
      'Today\'s shift is over.\nYou can still start a timer below.';

  @override
  String get idleAfterShiftAction => 'Open schedule';

  @override
  String get dayOff => 'Day off';

  @override
  String get pickWeekdayPattern => 'Choose work pattern';

  @override
  String get noPatternsYet => 'No patterns yet. Add one first.';

  @override
  String get todayPattern => 'Today\'s pattern';

  @override
  String get weekdaysHint => 'Tap a weekday to change its pattern';

  @override
  String get scheduleSetupTitle => 'Set your work hours';

  @override
  String get scheduleSetupBody =>
      'Enter your usual start and end times. Weekends are optional.';

  @override
  String get scheduleSetupDaysOptional => 'Work on weekends (optional)';

  @override
  String get scheduleSetupSave => 'Save';

  @override
  String get scheduleSetupDone => 'Schedule saved';

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
  String get moodSleepy => 'Sleepy';

  @override
  String get moodHungry => 'Hungry';

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
  String get moodHungry1 => 'Hungry. Food first is allowed.';

  @override
  String get moodHungry2 => 'Sitting here hungry. Time still shrinks.';

  @override
  String get moodHungry3 => 'A meal, and this chunk. Both sound good.';

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

  @override
  String get shiftClock => 'Until';

  @override
  String hourNow(int count) {
    return 'This hour ($count)';
  }

  @override
  String get chunkDone => 'Done';

  @override
  String get moodTitle => 'Mood right now?';

  @override
  String get moodAuto => 'Auto (follow progress)';

  @override
  String get todaySoFar => 'Today';

  @override
  String get toolCall => 'Fake call';

  @override
  String get toolBreak => 'Break';

  @override
  String get toolExcuse => 'Excuse\ngenerator';

  @override
  String get toolAway => 'Camouflage';

  @override
  String get moodCheer => 'Trying';

  @override
  String get moodFine => 'Good';

  @override
  String get moodFine1 => 'Today feels a little lighter.';

  @override
  String get moodFine2 => 'This pace is enough. No need to push.';

  @override
  String get moodFine3 => 'Not a bad day. Keep going like this.';

  @override
  String get moodAway => 'Slacking';

  @override
  String get homePause => 'Pause';

  @override
  String get excuseTitle => 'An excuse';

  @override
  String get excuseCopied => 'Copied';

  @override
  String get excuse1 => 'A call came in. I\'ll step out.';

  @override
  String get excuse2 => 'Printing something. Back in a minute.';

  @override
  String get excuse3 => 'Restroom. Won\'t be long.';

  @override
  String get excuse4 => 'Checking a file in the other room.';

  @override
  String get excuse5 => 'Grabbing my charger.';

  @override
  String get labTitle => 'Idle Lab';

  @override
  String get labSubtitle => 'Prompts from everyone';

  @override
  String get labToday => 'Today\'s prompt';

  @override
  String get labTodayEmpty => 'In preparation';

  @override
  String get labTodayPreparingHelp => 'Coming soon.';

  @override
  String get labSeeAll => 'All prompts';

  @override
  String get labSit => 'At a desk';

  @override
  String get labStand => 'On your feet';

  @override
  String get labQuiet => 'Quietly';

  @override
  String get labSitHelp => 'Something for your hands';

  @override
  String get labStandHelp => 'Something for your head';

  @override
  String get labQuietHelp => 'Short, and easy to hide';

  @override
  String get labSafety =>
      'Don\'t open this while driving or doing something risky.';

  @override
  String get labPropose => 'Suggest a prompt';

  @override
  String get labEntries => 'Answers';

  @override
  String get labEmptyEntries => 'Nobody yet. You can be first.';

  @override
  String get labEmptyList => 'Nothing in this filter.';

  @override
  String get labAnswer => 'Answer';

  @override
  String get labAnswerHint => 'One short line';

  @override
  String get labConfirmPost => 'Send this?';

  @override
  String get labSend => 'Send';

  @override
  String get labPosted => 'Sent';

  @override
  String get labDrawLater => 'Drawing comes next.';

  @override
  String get labPhotoHint => 'Pick one photo to post.';

  @override
  String get labPhotoPick => 'Choose photo';

  @override
  String get labPhotoReplace => 'Choose another';

  @override
  String get labProfileTitle => 'Lab profile';

  @override
  String get labProfileHint => 'Name and icon shown in Boredom Lab.';

  @override
  String get labProfileName => 'Display name';

  @override
  String get labProfilePickIcon => 'Choose icon';

  @override
  String get labProfileSave => 'Save';

  @override
  String get labProfileSaved => 'Profile saved.';

  @override
  String get labPhotoPolicyWarning =>
      'Do not post images that break copyright, privacy, or community rules. We may hide posts and suspend accounts for serious violations.';

  @override
  String get labFailPhotoEmpty => 'Choose a photo before sending.';

  @override
  String get labReportPhoto => '(Photo post)';

  @override
  String get labLike => 'Like';

  @override
  String get labReport => 'Report';

  @override
  String get labReported => 'Got it';

  @override
  String get labLocalOnly =>
      'This stays on this iPhone. Other people won\'t see it.';

  @override
  String get labLoadError =>
      'Couldn\'t load the latest. Showing what we already have.';

  @override
  String get labLoadFailed =>
      'Couldn\'t load prompts. Check your connection and try again.';

  @override
  String get labReload => 'Reload';

  @override
  String get labOpen => 'Open';

  @override
  String get labClosed => 'Closed';

  @override
  String labCount(int count) {
    return '$count answers';
  }

  @override
  String get labJoined => 'You joined';

  @override
  String get labNotJoined => 'Not yet';

  @override
  String labUntil(String time) {
    return 'Until $time';
  }

  @override
  String get labChoiceResult => 'How people answered';

  @override
  String get labCorrect => 'That\'s it';

  @override
  String get labWrong => 'Not that one';

  @override
  String get labYourAnswer => 'Your answer';

  @override
  String get labProposeTitle => 'Prompt';

  @override
  String get labProposeBody => 'Notes';

  @override
  String get labProposePickGenre => 'Pick a genre first';

  @override
  String get labProposeChangeGenre => 'Change genre';

  @override
  String get labProposeTitleHintOgiri => 'e.g. A company rule you\'d hate';

  @override
  String get labProposeTitleHintChoice => 'e.g. Leave on time or a raise?';

  @override
  String get labProposeTitleHintQuiz => 'e.g. Which bread can\'t you eat?';

  @override
  String get labProposeTitleHintDraw => 'e.g. Title this meeting doodle';

  @override
  String get labProposeTitleHintPen => 'e.g. One line to the boss, fine hand';

  @override
  String get labProposeBodyHint => 'Optional. Defaults to “Answer freely.”';

  @override
  String get labProposeBodyDefault => 'Answer freely.';

  @override
  String get labCategory => 'Where it fits';

  @override
  String get labProposeFormat => 'How they answer';

  @override
  String get labFormatOgiri => 'Caption';

  @override
  String get labFormatQuiz => 'Quiz';

  @override
  String get labFormatChoice => 'Two choices';

  @override
  String get labFormatDraw => 'Drawing';

  @override
  String get labChoicesHint => 'Choices, one per line';

  @override
  String get labCorrectOptional => 'The right answer can wait for a review.';

  @override
  String get labProposeSend => 'Send the suggestion';

  @override
  String get labProposeDone =>
      'Sent. It stays private until someone publishes it.';

  @override
  String get labReview => 'Review prompts';

  @override
  String get labSeedOgiri => 'Upload 20 ogiri prompts to Firestore';

  @override
  String labSeedOgiriDone(int count) {
    return 'Uploaded $count ogiri prompts.';
  }

  @override
  String get labSeedDraw => 'Upload 20 drawing prompts to Firestore';

  @override
  String labSeedDrawDone(int count) {
    return 'Uploaded $count drawing prompts.';
  }

  @override
  String get labSeedPen => 'Upload 20 penmanship prompts to Firestore';

  @override
  String labSeedPenDone(int count) {
    return 'Uploaded $count penmanship prompts.';
  }

  @override
  String get labReviewLocked =>
      'Review opens only for the signed-in operator account.';

  @override
  String get labPending => 'Waiting';

  @override
  String get labAccepted => 'Accepted';

  @override
  String get labRejected => 'Declined';

  @override
  String get labAccept => 'Accept';

  @override
  String get labReject => 'Decline';

  @override
  String get labPublish => 'Publish';

  @override
  String get labPublished => 'Published';

  @override
  String get labHide => 'Hide';

  @override
  String get labHidden => 'Hidden';

  @override
  String get labDeleteEntry => 'Delete post';

  @override
  String get labDeleteEntryConfirm =>
      'Delete this post? Likes on it will be removed too.';

  @override
  String get labDeletedEntry => 'Deleted';

  @override
  String get labReports => 'Reports';

  @override
  String get labNoReports => 'No reports';

  @override
  String get labNoProposals => 'No suggestions yet';

  @override
  String get labOfficial => 'Write an official prompt';

  @override
  String get labFeatured => 'Feature today';

  @override
  String get labNotFound => 'That prompt isn\'t here.';

  @override
  String get labAll => 'All';

  @override
  String get labSortCount => 'Most answers';

  @override
  String get labRank => 'Liked';

  @override
  String get labRankEmpty => 'No likes yet. Reading is enough.';

  @override
  String get labFailEmpty => 'Write something first.';

  @override
  String get labFailLong => 'That\'s a bit long.';

  @override
  String get labFailAlready => 'You already sent one.';

  @override
  String get labFailClosed => 'This one is closed.';

  @override
  String get labFailSelf => 'You can\'t like your own.';

  @override
  String get labFailForbidden => 'That one\'s for the operator.';

  @override
  String get labFailOffline => 'It didn\'t go through.';

  @override
  String get labFailInvalid => 'That doesn\'t fit this prompt.';

  @override
  String get labFailContact => 'Leave out phone numbers and email addresses.';

  @override
  String get homeShotPick => 'Choose a screenshot';

  @override
  String get homeShotHelp =>
      'Use a screenshot of your real home screen for camouflage.';

  @override
  String get homeShotFree => 'Free accounts use the built-in home screen.';

  @override
  String get premiumOfferHomeShot => 'Use your own home screen for camouflage';

  @override
  String get shiftFrom => 'Start';

  @override
  String get shiftTo => 'End';

  @override
  String get chunkNow => 'Now';

  @override
  String get toolLab => 'Idle Lab';

  @override
  String get mascotTitle => 'Character';

  @override
  String get mascotChick => 'Chick';

  @override
  String get mascotSloth => 'Sloth';

  @override
  String get settingsWork => 'Work';

  @override
  String get settingsNotify => 'Notices';

  @override
  String get settingsTimer => 'Timer';

  @override
  String get settingsMore => 'More';

  @override
  String get camouflageFirst =>
      'This screen makes it harder to tell this app is open. Tap the top right to come back.';

  @override
  String get camouflageFirstGo => 'Use this screen';

  @override
  String get labTapToPost => 'Join';

  @override
  String get labOthers => 'Other prompts';

  @override
  String get labOthersHelp => 'Browse by genre';

  @override
  String get labFormatPen => 'Fine hand';

  @override
  String get labTabChoice => 'The hard choice';

  @override
  String get chickNormal4 =>
      'If you haven\'t started, this is the first chunk.';

  @override
  String get chickNormal5 =>
      'It doesn\'t have to be good. Sitting here counts.';

  @override
  String get chickTired4 => 'A heavy day still gets smaller.';

  @override
  String get chickTired5 => 'Motivation can show up later. Or not.';

  @override
  String get chickHappy4 => 'Stay like this. It\'s a little easier.';

  @override
  String get chickHappy5 => 'As the chunks drop, so do the shoulders.';

  @override
  String get chickCheer4 => 'Past the middle. The rest can drift.';

  @override
  String get chickCheer5 => 'You sat this long. That\'s enough.';

  @override
  String get chickAttention4 => 'Near the door. No need to stand yet.';

  @override
  String get chickAttention5 => 'Not much left. Breathing is enough.';

  @override
  String get moodHeavy4 => 'Stay heavy. Time moves anyway.';

  @override
  String get moodHeavy5 => 'Today doesn\'t have to feel light.';

  @override
  String get moodHungry4 => 'Hungry, and the chunks still shrink.';

  @override
  String get moodHungry5 => 'Eat first if you want. This chunk will wait.';

  @override
  String get moodSleepy4 => 'Doze. The clock is awake.';

  @override
  String get moodSleepy5 => 'Eyes closed still counts as moving.';

  @override
  String get moodFine4 => 'This mood is about right.';

  @override
  String get moodFine5 => 'No need to cheer it up. This pace is fine.';
}
