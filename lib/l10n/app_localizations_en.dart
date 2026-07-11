// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Hide. Camouflage. Challenge.';

  @override
  String get homeTagline => 'Paint yourself. Blend in. Vanish.';

  @override
  String get homeHideCta => 'Hide!';

  @override
  String get homeHideSub => 'Camouflage yourself in a photo';

  @override
  String get homeSeekCta => 'Seek!';

  @override
  String get homeSeekSub => 'Hunt creatures hidden by others';

  @override
  String get getStarted => 'Get started';

  @override
  String get onboardTitle1 => 'Hide Inklings in your photos';

  @override
  String get onboardBody1 =>
      'Drop original little creatures anywhere in your own pictures.';

  @override
  String get onboardTitle2 => 'Camouflage them by hand';

  @override
  String get onboardBody2 =>
      'Paint the colours of the scene onto each Inkling to make it vanish.';

  @override
  String get onboardTitle3 => 'Challenge your friends';

  @override
  String get onboardBody3 =>
      'Share the puzzle. They tap to find what you hid — against the clock.';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialTitle => 'Two Inklings are hiding here';

  @override
  String get tutorialFindBody => 'Tap them to catch them!';

  @override
  String get tutorialOneLeft => 'Nice! One more…';

  @override
  String get tutorialDoneTitle => 'You\'ve got it!';

  @override
  String get tutorialDoneBody =>
      'Players paint their Inklings with the scene\'s colours until they vanish. Your turn.';

  @override
  String get tutorialCreateCta => 'Hide your first Inkling';

  @override
  String get tutorialExploreCta => 'Explore challenges';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccount => 'Create your account';

  @override
  String get displayName => 'Display name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get haveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get newHereCreate => 'New here? Create an account';

  @override
  String get orLabel => 'or';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get enterName => 'Enter a name';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get minChars => 'Min 6 characters';

  @override
  String get navFeed => 'Feed';

  @override
  String get navDaily => 'Daily';

  @override
  String get navRanks => 'Ranks';

  @override
  String get navProfile => 'Profile';

  @override
  String get feedTrending => '🔥 Trending now';

  @override
  String get feedEmptyTitle => 'No challenges yet';

  @override
  String get feedEmptyBody => 'Be the first to hide some Inklings!';

  @override
  String get createOne => 'Create one';

  @override
  String get premium => 'Premium';

  @override
  String get newChallenge => 'New challenge';

  @override
  String get choosePhotoTitle => 'Choose a photo to hide in';

  @override
  String get choosePhotoBody =>
      'Pick a busy, colourful scene — it makes camouflage more fun.';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get fromGallerySub => 'Use one of your own pictures';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get takePhotoSub => 'Snap something right now';

  @override
  String get toolMove => 'Move';

  @override
  String get toolBrush => 'Brush';

  @override
  String get toolPipette => 'Pipette';

  @override
  String get toolErase => 'Erase';

  @override
  String get toolAdd => 'Add';

  @override
  String get toolZoom => 'Zoom';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get pickAnInkling => 'Pick an Inkling';

  @override
  String get inklingLimitTitle => 'Inkling limit reached';

  @override
  String inklingLimitBody(int free, int premium) {
    return 'Free challenges allow up to $free Inklings. Go Premium to hide up to $premium.';
  }

  @override
  String get seePremium => 'See Premium';

  @override
  String get addInklingFirst => 'Add at least one Inkling first';

  @override
  String get nameYourChallenge => 'Name your challenge';

  @override
  String get challengeHint => 'e.g. Spot the six!';

  @override
  String get cancel => 'Cancel';

  @override
  String get publish => 'Publish';

  @override
  String publishFailed(String error) {
    return 'Publish failed: $error';
  }

  @override
  String get challengePublished => 'Challenge published! 🎉';

  @override
  String get shareSubtitle => 'Share the puzzle — the answer stays hidden.';

  @override
  String get viewChallenge => 'View challenge';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get play => 'Play';

  @override
  String get giveUpReveal => 'Give up & reveal';

  @override
  String get perfect => 'Perfect! 🏆';

  @override
  String get roundOver => 'Round over';

  @override
  String get found => 'Found';

  @override
  String get time => 'Time';

  @override
  String get score => 'Score';

  @override
  String get theSolution => 'The solution';

  @override
  String get playAgain => 'Play again';

  @override
  String get challengeNotFound => 'Challenge not found';

  @override
  String get goBack => 'Go back';

  @override
  String get comments => 'Comments';

  @override
  String get beFirstComment => 'Be the first to comment!';

  @override
  String get addComment => 'Add a comment…';

  @override
  String get like => 'Like';

  @override
  String plays(int count) {
    return '$count plays';
  }

  @override
  String hidden(int count) {
    return '$count hidden';
  }

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get matchSystem => 'Match system';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get content => 'Content';

  @override
  String get characterPacks => 'Character packs';

  @override
  String get achievements => 'Achievements';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Sign out';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String xpValue(int xp) {
    return '$xp XP';
  }

  @override
  String toNextLevel(int percent, int next) {
    return '$percent% to level $next';
  }

  @override
  String get created => 'Created';

  @override
  String get solved => 'Solved';

  @override
  String get dayStreak => 'Day streak';

  @override
  String get badges => 'Badges';

  @override
  String get seeAll => 'See all';

  @override
  String get yourChallenges => 'Your challenges';

  @override
  String get noChallengesYet => 'No challenges created yet.';

  @override
  String get rankings => 'Rankings';

  @override
  String get topPlayers => 'Top players';

  @override
  String get creators => 'Creators';

  @override
  String get premiumTitle => 'Inkognito Premium';

  @override
  String get unlockEverything => 'Unlock everything';

  @override
  String get unlockSub => 'Go ad-free and get every creature pack.';

  @override
  String get restore => 'Restore';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get welcomePremium => 'Welcome to Premium! 🎉';

  @override
  String get purchaseCancelled => 'Purchase was cancelled';

  @override
  String get daily => 'Daily';

  @override
  String get todaysPicks => 'Today\'s picks';

  @override
  String get dailySub =>
      'Fresh puzzles, updated every day. Keep your streak alive!';

  @override
  String get nothingTodayTitle => 'Nothing yet today';

  @override
  String get nothingTodayBody => 'Check back later or create the first one.';
}
