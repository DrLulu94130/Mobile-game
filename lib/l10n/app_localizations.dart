import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Hide. Camouflage. Challenge.'**
  String get appTagline;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Paint yourself. Blend in. Vanish.'**
  String get homeTagline;

  /// No description provided for @homeHideCta.
  ///
  /// In en, this message translates to:
  /// **'Hide!'**
  String get homeHideCta;

  /// No description provided for @homeHideSub.
  ///
  /// In en, this message translates to:
  /// **'Camouflage yourself in a photo'**
  String get homeHideSub;

  /// No description provided for @homeSeekCta.
  ///
  /// In en, this message translates to:
  /// **'Seek!'**
  String get homeSeekCta;

  /// No description provided for @homeSeekSub.
  ///
  /// In en, this message translates to:
  /// **'Hunt creatures hidden by others'**
  String get homeSeekSub;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'Hide Inklings in your photos'**
  String get onboardTitle1;

  /// No description provided for @onboardBody1.
  ///
  /// In en, this message translates to:
  /// **'Drop original little creatures anywhere in your own pictures.'**
  String get onboardBody1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'Camouflage them by hand'**
  String get onboardTitle2;

  /// No description provided for @onboardBody2.
  ///
  /// In en, this message translates to:
  /// **'Paint the colours of the scene onto each Inkling to make it vanish.'**
  String get onboardBody2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'Challenge your friends'**
  String get onboardTitle3;

  /// No description provided for @onboardBody3.
  ///
  /// In en, this message translates to:
  /// **'Share the puzzle. They tap to find what you hid — against the clock.'**
  String get onboardBody3;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

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

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccountSignIn;

  /// No description provided for @newHereCreate.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreate;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLabel;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @minChars.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get minChars;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get navDaily;

  /// No description provided for @navRanks.
  ///
  /// In en, this message translates to:
  /// **'Ranks'**
  String get navRanks;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @feedTrending.
  ///
  /// In en, this message translates to:
  /// **'🔥 Trending now'**
  String get feedTrending;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No challenges yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to hide some Inklings!'**
  String get feedEmptyBody;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @newChallenge.
  ///
  /// In en, this message translates to:
  /// **'New challenge'**
  String get newChallenge;

  /// No description provided for @choosePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo to hide in'**
  String get choosePhotoTitle;

  /// No description provided for @choosePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a busy, colourful scene — it makes camouflage more fun.'**
  String get choosePhotoBody;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get fromGallery;

  /// No description provided for @fromGallerySub.
  ///
  /// In en, this message translates to:
  /// **'Use one of your own pictures'**
  String get fromGallerySub;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @takePhotoSub.
  ///
  /// In en, this message translates to:
  /// **'Snap something right now'**
  String get takePhotoSub;

  /// No description provided for @toolMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get toolMove;

  /// No description provided for @toolBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get toolBrush;

  /// No description provided for @toolPipette.
  ///
  /// In en, this message translates to:
  /// **'Pipette'**
  String get toolPipette;

  /// No description provided for @toolErase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get toolErase;

  /// No description provided for @toolAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get toolAdd;

  /// No description provided for @toolZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get toolZoom;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @pickAnInkling.
  ///
  /// In en, this message translates to:
  /// **'Pick an Inkling'**
  String get pickAnInkling;

  /// No description provided for @inklingLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Inkling limit reached'**
  String get inklingLimitTitle;

  /// No description provided for @inklingLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Free challenges allow up to {free} Inklings. Go Premium to hide up to {premium}.'**
  String inklingLimitBody(int free, int premium);

  /// No description provided for @seePremium.
  ///
  /// In en, this message translates to:
  /// **'See Premium'**
  String get seePremium;

  /// No description provided for @addInklingFirst.
  ///
  /// In en, this message translates to:
  /// **'Add at least one Inkling first'**
  String get addInklingFirst;

  /// No description provided for @nameYourChallenge.
  ///
  /// In en, this message translates to:
  /// **'Name your challenge'**
  String get nameYourChallenge;

  /// No description provided for @challengeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Spot the six!'**
  String get challengeHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Publish failed: {error}'**
  String publishFailed(String error);

  /// No description provided for @challengePublished.
  ///
  /// In en, this message translates to:
  /// **'Challenge published! 🎉'**
  String get challengePublished;

  /// No description provided for @shareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share the puzzle — the answer stays hidden.'**
  String get shareSubtitle;

  /// No description provided for @viewChallenge.
  ///
  /// In en, this message translates to:
  /// **'View challenge'**
  String get viewChallenge;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @giveUpReveal.
  ///
  /// In en, this message translates to:
  /// **'Give up & reveal'**
  String get giveUpReveal;

  /// No description provided for @perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect! 🏆'**
  String get perfect;

  /// No description provided for @roundOver.
  ///
  /// In en, this message translates to:
  /// **'Round over'**
  String get roundOver;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get found;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @theSolution.
  ///
  /// In en, this message translates to:
  /// **'The solution'**
  String get theSolution;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @challengeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Challenge not found'**
  String get challengeNotFound;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @beFirstComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get beFirstComment;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get addComment;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @plays.
  ///
  /// In en, this message translates to:
  /// **'{count} plays'**
  String plays(int count);

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'{count} hidden'**
  String hidden(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @matchSystem.
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get matchSystem;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @characterPacks.
  ///
  /// In en, this message translates to:
  /// **'Character packs'**
  String get characterPacks;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @xpValue.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String xpValue(int xp);

  /// No description provided for @toNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to level {next}'**
  String toNextLevel(int percent, int next);

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @solved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get solved;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get dayStreak;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @yourChallenges.
  ///
  /// In en, this message translates to:
  /// **'Your challenges'**
  String get yourChallenges;

  /// No description provided for @noChallengesYet.
  ///
  /// In en, this message translates to:
  /// **'No challenges created yet.'**
  String get noChallengesYet;

  /// No description provided for @rankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get rankings;

  /// No description provided for @topPlayers.
  ///
  /// In en, this message translates to:
  /// **'Top players'**
  String get topPlayers;

  /// No description provided for @creators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get creators;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Inkognito Premium'**
  String get premiumTitle;

  /// No description provided for @unlockEverything.
  ///
  /// In en, this message translates to:
  /// **'Unlock everything'**
  String get unlockEverything;

  /// No description provided for @unlockSub.
  ///
  /// In en, this message translates to:
  /// **'Go ad-free and get every creature pack.'**
  String get unlockSub;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @welcomePremium.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium! 🎉'**
  String get welcomePremium;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase was cancelled'**
  String get purchaseCancelled;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @todaysPicks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s picks'**
  String get todaysPicks;

  /// No description provided for @dailySub.
  ///
  /// In en, this message translates to:
  /// **'Fresh puzzles, updated every day. Keep your streak alive!'**
  String get dailySub;

  /// No description provided for @nothingTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet today'**
  String get nothingTodayTitle;

  /// No description provided for @nothingTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Check back later or create the first one.'**
  String get nothingTodayBody;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
