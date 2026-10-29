import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ozio'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'A timer for people who\'d rather not'**
  String get tagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @endTimeMode.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTimeMode;

  /// No description provided for @durationMode.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationMode;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Chunk'**
  String get interval;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @useShift.
  ///
  /// In en, this message translates to:
  /// **'Use today\'s shift'**
  String get useShift;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get remaining;

  /// No description provided for @chunks.
  ///
  /// In en, this message translates to:
  /// **'Chunks'**
  String get chunks;

  /// No description provided for @freeTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re free!'**
  String get freeTitle;

  /// No description provided for @freeBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s the day. Go do something that isn\'t work.'**
  String get freeBody;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get goHome;

  /// No description provided for @seeHistory.
  ///
  /// In en, this message translates to:
  /// **'See history'**
  String get seeHistory;

  /// No description provided for @extend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get extend;

  /// No description provided for @endEarly.
  ///
  /// In en, this message translates to:
  /// **'Stop here'**
  String get endEarly;

  /// No description provided for @earlyDone.
  ///
  /// In en, this message translates to:
  /// **'Stopping here.'**
  String get earlyDone;

  /// No description provided for @noSession.
  ///
  /// In en, this message translates to:
  /// **'Nothing running yet.'**
  String get noSession;

  /// No description provided for @breaksKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Breaks keep counting. The end time stays put.'**
  String get breaksKeepGoing;

  /// No description provided for @noPause.
  ///
  /// In en, this message translates to:
  /// **'There\'s no pause. It just keeps going.'**
  String get noPause;

  /// No description provided for @notifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifyTitle;

  /// No description provided for @notifyChunk.
  ///
  /// In en, this message translates to:
  /// **'Chunk complete'**
  String get notifyChunk;

  /// No description provided for @notifyEnd.
  ///
  /// In en, this message translates to:
  /// **'Timer finished'**
  String get notifyEnd;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get vibration;

  /// No description provided for @vibrationHelp.
  ///
  /// In en, this message translates to:
  /// **'Haptics play while Ozio is open. Notification vibration follows the iPhone mute switch.'**
  String get vibrationHelp;

  /// No description provided for @endAction.
  ///
  /// In en, this message translates to:
  /// **'When it ends'**
  String get endAction;

  /// No description provided for @actionCelebration.
  ///
  /// In en, this message translates to:
  /// **'Freedom screen'**
  String get actionCelebration;

  /// No description provided for @actionHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get actionHome;

  /// No description provided for @actionHistory.
  ///
  /// In en, this message translates to:
  /// **'Open history'**
  String get actionHistory;

  /// No description provided for @visual.
  ///
  /// In en, this message translates to:
  /// **'Timer look'**
  String get visual;

  /// No description provided for @visualHelp.
  ///
  /// In en, this message translates to:
  /// **'These are prototypes. Switch them and compare.'**
  String get visualHelp;

  /// No description provided for @visualTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get visualTiles;

  /// No description provided for @visualMap.
  ///
  /// In en, this message translates to:
  /// **'Stage map'**
  String get visualMap;

  /// No description provided for @visualCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get visualCharacter;

  /// No description provided for @visualGauge.
  ///
  /// In en, this message translates to:
  /// **'Gauge'**
  String get visualGauge;

  /// No description provided for @showCharacter.
  ///
  /// In en, this message translates to:
  /// **'Show character'**
  String get showCharacter;

  /// No description provided for @autoStart.
  ///
  /// In en, this message translates to:
  /// **'Start at the scheduled time'**
  String get autoStart;

  /// No description provided for @autoStartHelp.
  ///
  /// In en, this message translates to:
  /// **'Starts on its own only while Ozio is open. If the app was closed, it asks next time you open it.'**
  String get autoStartHelp;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Work schedule'**
  String get schedule;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @camouflage.
  ///
  /// In en, this message translates to:
  /// **'Camouflage'**
  String get camouflage;

  /// No description provided for @fakeCall.
  ///
  /// In en, this message translates to:
  /// **'Fake call'**
  String get fakeCall;

  /// No description provided for @trigger.
  ///
  /// In en, this message translates to:
  /// **'How to switch back'**
  String get trigger;

  /// No description provided for @triggerCorner.
  ///
  /// In en, this message translates to:
  /// **'Tap the top right'**
  String get triggerCorner;

  /// No description provided for @triggerLong.
  ///
  /// In en, this message translates to:
  /// **'Long press'**
  String get triggerLong;

  /// No description provided for @triggerSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe down'**
  String get triggerSwipe;

  /// No description provided for @camouflageHint.
  ///
  /// In en, this message translates to:
  /// **'A static screen inside Ozio. It does not pretend to be the iPhone Home Screen.'**
  String get camouflageHint;

  /// No description provided for @backHintCorner.
  ///
  /// In en, this message translates to:
  /// **'Tap the top right to go back'**
  String get backHintCorner;

  /// No description provided for @backHintLong.
  ///
  /// In en, this message translates to:
  /// **'Long press to go back'**
  String get backHintLong;

  /// No description provided for @backHintSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe down to go back'**
  String get backHintSwipe;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call now'**
  String get callNow;

  /// No description provided for @callLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get callLater;

  /// No description provided for @callers.
  ///
  /// In en, this message translates to:
  /// **'Callers'**
  String get callers;

  /// No description provided for @weeklyLimit.
  ///
  /// In en, this message translates to:
  /// **'Free: once a week'**
  String get weeklyLimit;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @weekReset.
  ///
  /// In en, this message translates to:
  /// **'The free call resets every Monday.'**
  String get weekReset;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get answer;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endCall;

  /// No description provided for @incoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get incoming;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'mobile'**
  String get mobile;

  /// No description provided for @startPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Start this shift?'**
  String get startPromptTitle;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startNow;

  /// No description provided for @notToday.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get notToday;

  /// No description provided for @patterns.
  ///
  /// In en, this message translates to:
  /// **'Patterns'**
  String get patterns;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekdays;

  /// No description provided for @holiday.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get holiday;

  /// No description provided for @customDay.
  ///
  /// In en, this message translates to:
  /// **'Different hours'**
  String get customDay;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endTime;

  /// No description provided for @offDay.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offDay;

  /// No description provided for @breakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakLabel;

  /// No description provided for @addBreak.
  ///
  /// In en, this message translates to:
  /// **'Add a break'**
  String get addBreak;

  /// No description provided for @noBreaks.
  ///
  /// In en, this message translates to:
  /// **'No breaks'**
  String get noBreaks;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @overtimeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get overtimeNone;

  /// No description provided for @memo.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get memo;

  /// No description provided for @memoHint.
  ///
  /// In en, this message translates to:
  /// **'One line, if you want'**
  String get memoHint;

  /// No description provided for @computedNote.
  ///
  /// In en, this message translates to:
  /// **'Overtime and total break time are calculated. They aren\'t stored twice.'**
  String get computedNote;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statusDone;

  /// No description provided for @statusEarly.
  ///
  /// In en, this message translates to:
  /// **'Stopped early'**
  String get statusEarly;

  /// No description provided for @extensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get extensions;

  /// No description provided for @originalEnd.
  ///
  /// In en, this message translates to:
  /// **'Original end'**
  String get originalEnd;

  /// No description provided for @actualStart.
  ///
  /// In en, this message translates to:
  /// **'Actual start'**
  String get actualStart;

  /// No description provided for @actualEnd.
  ///
  /// In en, this message translates to:
  /// **'Actual end'**
  String get actualEnd;

  /// No description provided for @achievement.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get achievement;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Using Ozio anonymously'**
  String get anonymous;

  /// No description provided for @registerEmail.
  ///
  /// In en, this message translates to:
  /// **'Keep this data with email'**
  String get registerEmail;

  /// No description provided for @registerGoogle.
  ///
  /// In en, this message translates to:
  /// **'Keep this data with Google'**
  String get registerGoogle;

  /// No description provided for @signInEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInEmail;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInGoogle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the account and its settings and history.'**
  String get deleteAccountBody;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @firebaseLocal.
  ///
  /// In en, this message translates to:
  /// **'Saved on this iPhone. Sign-in needs the Firebase project.'**
  String get firebaseLocal;

  /// No description provided for @premiumPitch.
  ///
  /// In en, this message translates to:
  /// **'A one-time purchase. Unlimited fake calls, your own callers, camouflage screens, ringtones, and more ways for the chick to talk.'**
  String get premiumPitch;

  /// No description provided for @premiumOwned.
  ///
  /// In en, this message translates to:
  /// **'Premium is on'**
  String get premiumOwned;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get restore;

  /// No description provided for @priceFallback.
  ///
  /// In en, this message translates to:
  /// **'¥500'**
  String get priceFallback;

  /// No description provided for @freeTier.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeTier;

  /// No description provided for @languageFollows.
  ///
  /// In en, this message translates to:
  /// **'Language follows the iPhone setting.'**
  String get languageFollows;

  /// No description provided for @customMinutes.
  ///
  /// In en, this message translates to:
  /// **'Chunk length in minutes'**
  String get customMinutes;

  /// No description provided for @customExtend.
  ///
  /// In en, this message translates to:
  /// **'Minutes to add'**
  String get customExtend;

  /// No description provided for @invalidMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 1 minute'**
  String get invalidMinutes;

  /// No description provided for @tooShort.
  ///
  /// In en, this message translates to:
  /// **'The end has to be at least a minute away'**
  String get tooShort;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used this week\'s free call'**
  String get limitReached;

  /// No description provided for @premiumRequired.
  ///
  /// In en, this message translates to:
  /// **'That\'s a Premium extra'**
  String get premiumRequired;

  /// No description provided for @encourage1.
  ///
  /// In en, this message translates to:
  /// **'A little further. You\'ve already done the hard part of starting.'**
  String get encourage1;

  /// No description provided for @encourage2.
  ///
  /// In en, this message translates to:
  /// **'Still here. That\'s the whole trick.'**
  String get encourage2;

  /// No description provided for @encourage3.
  ///
  /// In en, this message translates to:
  /// **'Future you is grateful. Present you can grumble.'**
  String get encourage3;

  /// No description provided for @encourage4.
  ///
  /// In en, this message translates to:
  /// **'One more chunk. Then the door.'**
  String get encourage4;

  /// No description provided for @encourage5.
  ///
  /// In en, this message translates to:
  /// **'You\'re allowed to be tired and still finish.'**
  String get encourage5;

  /// No description provided for @burstOne.
  ///
  /// In en, this message translates to:
  /// **'Chunk cleared!'**
  String get burstOne;

  /// No description provided for @burstMany.
  ///
  /// In en, this message translates to:
  /// **'Chunks cleared!'**
  String get burstMany;

  /// No description provided for @addCaller.
  ///
  /// In en, this message translates to:
  /// **'Add a caller'**
  String get addCaller;

  /// No description provided for @callerName.
  ///
  /// In en, this message translates to:
  /// **'Caller name'**
  String get callerName;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No days saved yet.'**
  String get emptyHistory;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get running;

  /// No description provided for @applyShift.
  ///
  /// In en, this message translates to:
  /// **'Count from the scheduled start'**
  String get applyShift;

  /// No description provided for @upcomingAuto.
  ///
  /// In en, this message translates to:
  /// **'Will start on its own at the scheduled time'**
  String get upcomingAuto;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get mins;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That sign-in isn\'t available yet'**
  String get authUnavailable;

  /// No description provided for @authInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the email address'**
  String get authInvalid;

  /// No description provided for @authWeak.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get authWeak;

  /// No description provided for @authExists.
  ///
  /// In en, this message translates to:
  /// **'That email is already registered. Sign in instead.'**
  String get authExists;

  /// No description provided for @authWrong.
  ///
  /// In en, this message translates to:
  /// **'Email or password didn\'t match'**
  String get authWrong;

  /// No description provided for @authRecent.
  ///
  /// In en, this message translates to:
  /// **'Sign in again, then delete the account'**
  String get authRecent;

  /// No description provided for @authCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get authCanceled;

  /// No description provided for @authUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish that'**
  String get authUnknown;

  /// No description provided for @purchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The App Store purchase isn\'t available'**
  String get purchaseUnavailable;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Ozio keeps going and will sync later.'**
  String get offline;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @newPattern.
  ///
  /// In en, this message translates to:
  /// **'New pattern'**
  String get newPattern;

  /// No description provided for @editPattern.
  ///
  /// In en, this message translates to:
  /// **'Edit pattern'**
  String get editPattern;

  /// No description provided for @continueTimer.
  ///
  /// In en, this message translates to:
  /// **'Open timer'**
  String get continueTimer;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'6 or more characters'**
  String get passwordHint;

  /// No description provided for @linkKeeps.
  ///
  /// In en, this message translates to:
  /// **'Registering keeps the history and settings you already have.'**
  String get linkKeeps;

  /// No description provided for @anonymousLoss.
  ///
  /// In en, this message translates to:
  /// **'An anonymous reinstall does not bring the data back. A registered account does.'**
  String get anonymousLoss;

  /// No description provided for @switchHelp.
  ///
  /// In en, this message translates to:
  /// **'Signing in to another account shows that account\'s data on this iPhone.'**
  String get switchHelp;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @stage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get muted;

  /// No description provided for @inCall.
  ///
  /// In en, this message translates to:
  /// **'Calling'**
  String get inCall;

  /// No description provided for @noShiftNeeded.
  ///
  /// In en, this message translates to:
  /// **'You can use the timer with no schedule.'**
  String get noShiftNeeded;

  /// No description provided for @intervalHelp.
  ///
  /// In en, this message translates to:
  /// **'The last chunk shrinks to fit whatever time is left.'**
  String get intervalHelp;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @requiredName.
  ///
  /// In en, this message translates to:
  /// **'Add a name'**
  String get requiredName;

  /// No description provided for @scheduledCall.
  ///
  /// In en, this message translates to:
  /// **'Call scheduled'**
  String get scheduledCall;

  /// No description provided for @cancelCall.
  ///
  /// In en, this message translates to:
  /// **'Cancel this call'**
  String get cancelCall;

  /// No description provided for @googleMissing.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in needs a CLIENT_ID in GoogleService-Info.plist.'**
  String get googleMissing;

  /// No description provided for @crossesMidnight.
  ///
  /// In en, this message translates to:
  /// **'This shift runs past midnight'**
  String get crossesMidnight;

  /// No description provided for @breakTotal.
  ///
  /// In en, this message translates to:
  /// **'Break total'**
  String get breakTotal;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @extendTotal.
  ///
  /// In en, this message translates to:
  /// **'Extended'**
  String get extendTotal;

  /// No description provided for @pickEnd.
  ///
  /// In en, this message translates to:
  /// **'Choose the end'**
  String get pickEnd;

  /// No description provided for @earlyBy.
  ///
  /// In en, this message translates to:
  /// **'Finished before the plan'**
  String get earlyBy;

  /// No description provided for @localAccount.
  ///
  /// In en, this message translates to:
  /// **'This iPhone only'**
  String get localAccount;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get registered;

  /// No description provided for @overrides.
  ///
  /// In en, this message translates to:
  /// **'Special days'**
  String get overrides;

  /// No description provided for @addOverride.
  ///
  /// In en, this message translates to:
  /// **'Add a day'**
  String get addOverride;

  /// No description provided for @deletePattern.
  ///
  /// In en, this message translates to:
  /// **'Delete pattern'**
  String get deletePattern;

  /// No description provided for @premiumCamouflage.
  ///
  /// In en, this message translates to:
  /// **'Long press and swipe are Premium'**
  String get premiumCamouflage;

  /// No description provided for @premiumCallers.
  ///
  /// In en, this message translates to:
  /// **'Custom callers are Premium'**
  String get premiumCallers;

  /// No description provided for @usedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Used this week'**
  String get usedThisWeek;

  /// No description provided for @ringing.
  ///
  /// In en, this message translates to:
  /// **'ringing'**
  String get ringing;

  /// No description provided for @notRunning.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notRunning;

  /// No description provided for @startTimer.
  ///
  /// In en, this message translates to:
  /// **'Start the timer'**
  String get startTimer;

  /// No description provided for @chunksAhead.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get chunksAhead;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayProgress;

  /// No description provided for @plannedEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get plannedEnd;

  /// No description provided for @extendChoose.
  ///
  /// In en, this message translates to:
  /// **'How much longer?'**
  String get extendChoose;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'A little longer. You can do it.'**
  String get keepGoing;

  /// No description provided for @historyWork.
  ///
  /// In en, this message translates to:
  /// **'Work history'**
  String get historyWork;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get viewCalendar;

  /// No description provided for @minuteChunk.
  ///
  /// In en, this message translates to:
  /// **' min chunks'**
  String get minuteChunk;

  /// No description provided for @hourChunk.
  ///
  /// In en, this message translates to:
  /// **' hour chunks'**
  String get hourChunk;

  /// No description provided for @intervalCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get intervalCustom;

  /// No description provided for @nowChunk.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowChunk;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @tutorialStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tutorialStart;

  /// No description provided for @tutorial1Title.
  ///
  /// In en, this message translates to:
  /// **'Split the time until you\'re done'**
  String get tutorial1Title;

  /// No description provided for @tutorial1Body.
  ///
  /// In en, this message translates to:
  /// **'Pick an end time and Ozio breaks the stretch into small chunks.'**
  String get tutorial1Body;

  /// No description provided for @tutorial2Title.
  ///
  /// In en, this message translates to:
  /// **'How long each chunk is'**
  String get tutorial2Title;

  /// No description provided for @tutorial2Body.
  ///
  /// In en, this message translates to:
  /// **'On the home screen, choose 15 min, 30 min, 1 hour, or your own length.'**
  String get tutorial2Body;

  /// No description provided for @tutorial3Title.
  ///
  /// In en, this message translates to:
  /// **'Where you are right now'**
  String get tutorial3Title;

  /// No description provided for @tutorial3Body.
  ///
  /// In en, this message translates to:
  /// **'The timer shows the current chunk, like Now 4:10–4:30.'**
  String get tutorial3Body;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Please update'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version can\'t continue.'**
  String get updateRequiredBody;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A newer version is out'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'You can keep using this one.'**
  String get updateAvailableBody;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @chickNormal1.
  ///
  /// In en, this message translates to:
  /// **'Starting is the hard part.'**
  String get chickNormal1;

  /// No description provided for @chickNormal2.
  ///
  /// In en, this message translates to:
  /// **'You can stay lazy. The chunks still shrink.'**
  String get chickNormal2;

  /// No description provided for @chickNormal3.
  ///
  /// In en, this message translates to:
  /// **'Small pieces, until the day ends.'**
  String get chickNormal3;

  /// No description provided for @chickTired1.
  ///
  /// In en, this message translates to:
  /// **'Still a long way. This chunk will end, though.'**
  String get chickTired1;

  /// No description provided for @chickTired2.
  ///
  /// In en, this message translates to:
  /// **'You don\'t need motivation. Time runs out first.'**
  String get chickTired2;

  /// No description provided for @chickTired3.
  ///
  /// In en, this message translates to:
  /// **'Sitting here still counts as progress.'**
  String get chickTired3;

  /// No description provided for @chickHappy1.
  ///
  /// In en, this message translates to:
  /// **'A little further. This pace is fine.'**
  String get chickHappy1;

  /// No description provided for @chickHappy2.
  ///
  /// In en, this message translates to:
  /// **'Not bad. The number is actually going down.'**
  String get chickHappy2;

  /// No description provided for @chickHappy3.
  ///
  /// In en, this message translates to:
  /// **'Finish this chunk, and one more is gone.'**
  String get chickHappy3;

  /// No description provided for @chickCheer1.
  ///
  /// In en, this message translates to:
  /// **'Halfway\'s gone. The view changed.'**
  String get chickCheer1;

  /// No description provided for @chickCheer2.
  ///
  /// In en, this message translates to:
  /// **'From here, time does the work.'**
  String get chickCheer2;

  /// No description provided for @chickCheer3.
  ///
  /// In en, this message translates to:
  /// **'That\'s something. I mean it.'**
  String get chickCheer3;

  /// No description provided for @chickAttention1.
  ///
  /// In en, this message translates to:
  /// **'Almost there. The door is in sight.'**
  String get chickAttention1;

  /// No description provided for @chickAttention2.
  ///
  /// In en, this message translates to:
  /// **'Nearly done. You can stop trying so hard.'**
  String get chickAttention2;

  /// No description provided for @chickAttention3.
  ///
  /// In en, this message translates to:
  /// **'Past this chunk, today is mostly over.'**
  String get chickAttention3;

  /// No description provided for @chickSurprise1.
  ///
  /// In en, this message translates to:
  /// **'The end time passed. You\'re still here.'**
  String get chickSurprise1;

  /// No description provided for @chickSurprise2.
  ///
  /// In en, this message translates to:
  /// **'Leaving time already arrived.'**
  String get chickSurprise2;

  /// No description provided for @chickSurprise3.
  ///
  /// In en, this message translates to:
  /// **'Overtime, then. The chunks still shrink.'**
  String get chickSurprise3;

  /// No description provided for @chickSleep1.
  ///
  /// In en, this message translates to:
  /// **'Break. Nothing is required here.'**
  String get chickSleep1;

  /// No description provided for @chickSleep2.
  ///
  /// In en, this message translates to:
  /// **'You can close your eyes for this one.'**
  String get chickSleep2;

  /// No description provided for @chickSleep3.
  ///
  /// In en, this message translates to:
  /// **'Stay like this until the break ends.'**
  String get chickSleep3;

  /// No description provided for @chickDone1.
  ///
  /// In en, this message translates to:
  /// **'Today\'s part is over.'**
  String get chickDone1;

  /// No description provided for @chickDone2.
  ///
  /// In en, this message translates to:
  /// **'You sat through it. Work can stop now.'**
  String get chickDone2;

  /// No description provided for @chickDone3.
  ///
  /// In en, this message translates to:
  /// **'You\'re free. You can leave.'**
  String get chickDone3;

  /// No description provided for @chickBack1.
  ///
  /// In en, this message translates to:
  /// **'The timer is moving. Pick up when you\'re back.'**
  String get chickBack1;

  /// No description provided for @chickBack2.
  ///
  /// In en, this message translates to:
  /// **'Step away. The chunks keep shrinking.'**
  String get chickBack2;

  /// No description provided for @chickBack3.
  ///
  /// In en, this message translates to:
  /// **'I\'ll keep it moving. No need to rush back.'**
  String get chickBack3;

  /// No description provided for @chickNotice1.
  ///
  /// In en, this message translates to:
  /// **'One chunk is done. On to the next.'**
  String get chickNotice1;

  /// No description provided for @chickNotice2.
  ///
  /// In en, this message translates to:
  /// **'It\'s getting smaller. You can see it.'**
  String get chickNotice2;

  /// No description provided for @chickNotice3.
  ///
  /// In en, this message translates to:
  /// **'One finished. That\'s enough.'**
  String get chickNotice3;

  /// No description provided for @chickGoodjob1.
  ///
  /// In en, this message translates to:
  /// **'A few are done. Not amazing. Still real.'**
  String get chickGoodjob1;

  /// No description provided for @chickGoodjob2.
  ///
  /// In en, this message translates to:
  /// **'Further along than it feels.'**
  String get chickGoodjob2;

  /// No description provided for @chickGoodjob3.
  ///
  /// In en, this message translates to:
  /// **'Stay seated. Another one will go.'**
  String get chickGoodjob3;

  /// No description provided for @chickLove1.
  ///
  /// In en, this message translates to:
  /// **'Today can stop here.'**
  String get chickLove1;

  /// No description provided for @chickLove2.
  ///
  /// In en, this message translates to:
  /// **'You finished it. That counts.'**
  String get chickLove2;

  /// No description provided for @chickLove3.
  ///
  /// In en, this message translates to:
  /// **'You can drop the work face now.'**
  String get chickLove3;

  /// No description provided for @lookHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get lookHome;

  /// No description provided for @lookNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get lookNotes;

  /// No description provided for @lookCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get lookCalendar;

  /// No description provided for @premiumLooks.
  ///
  /// In en, this message translates to:
  /// **'Notes and Calendar are Premium'**
  String get premiumLooks;

  /// No description provided for @chickVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'How the chick talks'**
  String get chickVoiceTitle;

  /// No description provided for @voicePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get voicePlain;

  /// No description provided for @voiceLazy.
  ///
  /// In en, this message translates to:
  /// **'Even lazier'**
  String get voiceLazy;

  /// No description provided for @voiceKansai.
  ///
  /// In en, this message translates to:
  /// **'Kansai'**
  String get voiceKansai;

  /// No description provided for @voiceCustom.
  ///
  /// In en, this message translates to:
  /// **'Your line'**
  String get voiceCustom;

  /// No description provided for @premiumVoice.
  ///
  /// In en, this message translates to:
  /// **'Extra voices are Premium'**
  String get premiumVoice;

  /// No description provided for @customLine.
  ///
  /// In en, this message translates to:
  /// **'One line for the chick'**
  String get customLine;

  /// No description provided for @moodHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get moodHeavy;

  /// No description provided for @moodSleepy.
  ///
  /// In en, this message translates to:
  /// **'Sleepy'**
  String get moodSleepy;

  /// No description provided for @moodHungry.
  ///
  /// In en, this message translates to:
  /// **'Hungry'**
  String get moodHungry;

  /// No description provided for @moodCall.
  ///
  /// In en, this message translates to:
  /// **'Call in this mood'**
  String get moodCall;

  /// No description provided for @premiumMoodCall.
  ///
  /// In en, this message translates to:
  /// **'The call after a mood is Premium'**
  String get premiumMoodCall;

  /// No description provided for @soundClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get soundClassic;

  /// No description provided for @soundSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get soundSoft;

  /// No description provided for @soundBright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get soundBright;

  /// No description provided for @premiumSounds.
  ///
  /// In en, this message translates to:
  /// **'Changing the ringtone is Premium'**
  String get premiumSounds;

  /// No description provided for @callBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'10 min before the end'**
  String get callBeforeEnd;

  /// No description provided for @beforeEndPassed.
  ///
  /// In en, this message translates to:
  /// **'That time has passed'**
  String get beforeEndPassed;

  /// No description provided for @noteMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk and eggs'**
  String get noteMilk;

  /// No description provided for @noteDentist.
  ///
  /// In en, this message translates to:
  /// **'Dentist, next week'**
  String get noteDentist;

  /// No description provided for @noteReturn.
  ///
  /// In en, this message translates to:
  /// **'Return the book'**
  String get noteReturn;

  /// No description provided for @noteMilkBody.
  ///
  /// In en, this message translates to:
  /// **'Buy them on the way home.'**
  String get noteMilkBody;

  /// No description provided for @noteDentistBody.
  ///
  /// In en, this message translates to:
  /// **'Afternoon. No work talk.'**
  String get noteDentistBody;

  /// No description provided for @noteReturnBody.
  ///
  /// In en, this message translates to:
  /// **'The due date is close.'**
  String get noteReturnBody;

  /// No description provided for @calLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get calLunch;

  /// No description provided for @voiceLazy1.
  ///
  /// In en, this message translates to:
  /// **'Ugh. Heavy.'**
  String get voiceLazy1;

  /// No description provided for @voiceLazy2.
  ///
  /// In en, this message translates to:
  /// **'Don\'t want to move. Time still shrinks.'**
  String get voiceLazy2;

  /// No description provided for @voiceLazy3.
  ///
  /// In en, this message translates to:
  /// **'Today can be like this.'**
  String get voiceLazy3;

  /// No description provided for @voiceLazy4.
  ///
  /// In en, this message translates to:
  /// **'Motivation is tomorrow\'s problem.'**
  String get voiceLazy4;

  /// No description provided for @voiceLazy5.
  ///
  /// In en, this message translates to:
  /// **'Sitting here is the job.'**
  String get voiceLazy5;

  /// No description provided for @voiceLazy6.
  ///
  /// In en, this message translates to:
  /// **'One more chunk. Probably.'**
  String get voiceLazy6;

  /// No description provided for @voiceKansai1.
  ///
  /// In en, this message translates to:
  /// **'Still a long way, huh.'**
  String get voiceKansai1;

  /// No description provided for @voiceKansai2.
  ///
  /// In en, this message translates to:
  /// **'It\'s coming along.'**
  String get voiceKansai2;

  /// No description provided for @voiceKansai3.
  ///
  /// In en, this message translates to:
  /// **'We\'ll take it easy.'**
  String get voiceKansai3;

  /// No description provided for @voiceKansai4.
  ///
  /// In en, this message translates to:
  /// **'A bit more until the end.'**
  String get voiceKansai4;

  /// No description provided for @voiceKansai5.
  ///
  /// In en, this message translates to:
  /// **'Nice. Nice.'**
  String get voiceKansai5;

  /// No description provided for @voiceKansai6.
  ///
  /// In en, this message translates to:
  /// **'You could just go home.'**
  String get voiceKansai6;

  /// No description provided for @moodHeavy1.
  ///
  /// In en, this message translates to:
  /// **'Heavy. I know.'**
  String get moodHeavy1;

  /// No description provided for @moodHeavy2.
  ///
  /// In en, this message translates to:
  /// **'You can stay like that. It\'s moving.'**
  String get moodHeavy2;

  /// No description provided for @moodHeavy3.
  ///
  /// In en, this message translates to:
  /// **'Today can be a heavy one.'**
  String get moodHeavy3;

  /// No description provided for @moodHungry1.
  ///
  /// In en, this message translates to:
  /// **'Hungry. Food first is allowed.'**
  String get moodHungry1;

  /// No description provided for @moodHungry2.
  ///
  /// In en, this message translates to:
  /// **'Sitting here hungry. Time still shrinks.'**
  String get moodHungry2;

  /// No description provided for @moodHungry3.
  ///
  /// In en, this message translates to:
  /// **'A meal, and this chunk. Both sound good.'**
  String get moodHungry3;

  /// No description provided for @moodSleepy1.
  ///
  /// In en, this message translates to:
  /// **'Sleepy.'**
  String get moodSleepy1;

  /// No description provided for @moodSleepy2.
  ///
  /// In en, this message translates to:
  /// **'Half-open eyes are enough.'**
  String get moodSleepy2;

  /// No description provided for @moodSleepy3.
  ///
  /// In en, this message translates to:
  /// **'Doze if you want.'**
  String get moodSleepy3;

  /// No description provided for @slack.
  ///
  /// In en, this message translates to:
  /// **'Step away'**
  String get slack;

  /// No description provided for @slackIntro.
  ///
  /// In en, this message translates to:
  /// **'This is for leaving your seat. It shows a work call, or swaps this app for another screen. Nobody is actually called.'**
  String get slackIntro;

  /// No description provided for @slackCall.
  ///
  /// In en, this message translates to:
  /// **'Pretend a call came in'**
  String get slackCall;

  /// No description provided for @slackHide.
  ///
  /// In en, this message translates to:
  /// **'Swap the screen'**
  String get slackHide;

  /// No description provided for @slackWeekly.
  ///
  /// In en, this message translates to:
  /// **'The free call is once a week.'**
  String get slackWeekly;

  /// No description provided for @slackMore.
  ///
  /// In en, this message translates to:
  /// **'Get more calls'**
  String get slackMore;

  /// No description provided for @shiftClock.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get shiftClock;

  /// No description provided for @hourNow.
  ///
  /// In en, this message translates to:
  /// **'This hour ({count})'**
  String hourNow(int count);

  /// No description provided for @chunkDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get chunkDone;

  /// No description provided for @moodTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood right now?'**
  String get moodTitle;

  /// No description provided for @todaySoFar.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todaySoFar;

  /// No description provided for @toolCall.
  ///
  /// In en, this message translates to:
  /// **'Fake call'**
  String get toolCall;

  /// No description provided for @toolBreak.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get toolBreak;

  /// No description provided for @toolExcuse.
  ///
  /// In en, this message translates to:
  /// **'Excuse\ngenerator'**
  String get toolExcuse;

  /// No description provided for @toolAway.
  ///
  /// In en, this message translates to:
  /// **'Step away'**
  String get toolAway;

  /// No description provided for @moodCheer.
  ///
  /// In en, this message translates to:
  /// **'Trying'**
  String get moodCheer;

  /// No description provided for @moodFine.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodFine;

  /// No description provided for @moodFine1.
  ///
  /// In en, this message translates to:
  /// **'Today feels a little lighter.'**
  String get moodFine1;

  /// No description provided for @moodFine2.
  ///
  /// In en, this message translates to:
  /// **'This pace is enough. No need to push.'**
  String get moodFine2;

  /// No description provided for @moodFine3.
  ///
  /// In en, this message translates to:
  /// **'Not a bad day. Keep going like this.'**
  String get moodFine3;

  /// No description provided for @moodAway.
  ///
  /// In en, this message translates to:
  /// **'Slacking'**
  String get moodAway;

  /// No description provided for @homePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get homePause;

  /// No description provided for @excuseTitle.
  ///
  /// In en, this message translates to:
  /// **'An excuse'**
  String get excuseTitle;

  /// No description provided for @excuseCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get excuseCopied;

  /// No description provided for @excuse1.
  ///
  /// In en, this message translates to:
  /// **'A call came in. I\'ll step out.'**
  String get excuse1;

  /// No description provided for @excuse2.
  ///
  /// In en, this message translates to:
  /// **'Printing something. Back in a minute.'**
  String get excuse2;

  /// No description provided for @excuse3.
  ///
  /// In en, this message translates to:
  /// **'Restroom. Won\'t be long.'**
  String get excuse3;

  /// No description provided for @excuse4.
  ///
  /// In en, this message translates to:
  /// **'Checking a file in the other room.'**
  String get excuse4;

  /// No description provided for @excuse5.
  ///
  /// In en, this message translates to:
  /// **'Grabbing my charger.'**
  String get excuse5;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
