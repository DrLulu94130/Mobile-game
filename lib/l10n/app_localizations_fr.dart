// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTagline => 'Cache. Camoufle. Défie.';

  @override
  String get homeTagline => 'Peins-toi. Fonds-toi. Disparais.';

  @override
  String get homeHideCta => 'Cache-toi !';

  @override
  String get homeHideSub => 'Camoufle-toi dans une photo';

  @override
  String get homeSeekCta => 'Cherche-les !';

  @override
  String get homeSeekSub => 'Traque les créatures cachées par les autres';

  @override
  String get getStarted => 'Commencer';

  @override
  String get onboardTitle1 => 'Cache des Inklings dans tes photos';

  @override
  String get onboardBody1 =>
      'Place de petites créatures originales n\'importe où dans tes propres images.';

  @override
  String get onboardTitle2 => 'Camoufle-les à la main';

  @override
  String get onboardBody2 =>
      'Peins les couleurs de la scène sur chaque Inkling pour le faire disparaître.';

  @override
  String get onboardTitle3 => 'Défie tes amis';

  @override
  String get onboardBody3 =>
      'Partage l\'énigme. Ils touchent l\'écran pour trouver ce que tu as caché — contre la montre.';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get createAccount => 'Crée ton compte';

  @override
  String get displayName => 'Nom d\'affichage';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get haveAccountSignIn => 'Déjà un compte ? Se connecter';

  @override
  String get newHereCreate => 'Nouveau ici ? Crée un compte';

  @override
  String get orLabel => 'ou';

  @override
  String get continueAsGuest => 'Continuer en invité';

  @override
  String get enterName => 'Entre un nom';

  @override
  String get enterValidEmail => 'Entre un e-mail valide';

  @override
  String get minChars => '6 caractères minimum';

  @override
  String get navFeed => 'Fil';

  @override
  String get navDaily => 'Du jour';

  @override
  String get navRanks => 'Classement';

  @override
  String get navProfile => 'Profil';

  @override
  String get feedTrending => '🔥 Tendances';

  @override
  String get feedEmptyTitle => 'Aucun défi pour l\'instant';

  @override
  String get feedEmptyBody => 'Sois le premier à cacher des Inklings !';

  @override
  String get createOne => 'En créer un';

  @override
  String get premium => 'Premium';

  @override
  String get newChallenge => 'Nouveau défi';

  @override
  String get choosePhotoTitle => 'Choisis une photo où te cacher';

  @override
  String get choosePhotoBody =>
      'Prends une scène chargée et colorée — le camouflage n\'en sera que plus amusant.';

  @override
  String get fromGallery => 'Depuis la galerie';

  @override
  String get fromGallerySub => 'Utilise une de tes propres photos';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get takePhotoSub => 'Capture quelque chose maintenant';

  @override
  String get toolMove => 'Déplacer';

  @override
  String get toolBrush => 'Pinceau';

  @override
  String get toolPipette => 'Pipette';

  @override
  String get toolErase => 'Gomme';

  @override
  String get toolAdd => 'Ajouter';

  @override
  String get toolZoom => 'Zoom';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get delete => 'Supprimer';

  @override
  String get done => 'Terminé';

  @override
  String get pickAnInkling => 'Choisis un Inkling';

  @override
  String get inklingLimitTitle => 'Limite d\'Inklings atteinte';

  @override
  String inklingLimitBody(int free, int premium) {
    return 'Les défis gratuits autorisent jusqu\'à $free Inklings. Passe Premium pour en cacher jusqu\'à $premium.';
  }

  @override
  String get seePremium => 'Voir Premium';

  @override
  String get addInklingFirst => 'Ajoute d\'abord au moins un Inkling';

  @override
  String get nameYourChallenge => 'Nomme ton défi';

  @override
  String get challengeHint => 'ex. Trouve les six !';

  @override
  String get cancel => 'Annuler';

  @override
  String get publish => 'Publier';

  @override
  String publishFailed(String error) {
    return 'Échec de la publication : $error';
  }

  @override
  String get challengePublished => 'Défi publié ! 🎉';

  @override
  String get shareSubtitle => 'Partage l\'énigme — la réponse reste cachée.';

  @override
  String get viewChallenge => 'Voir le défi';

  @override
  String get linkCopied => 'Lien copié dans le presse-papiers';

  @override
  String get play => 'Jouer';

  @override
  String get giveUpReveal => 'Abandonner & révéler';

  @override
  String get perfect => 'Parfait ! 🏆';

  @override
  String get roundOver => 'Partie terminée';

  @override
  String get found => 'Trouvés';

  @override
  String get time => 'Temps';

  @override
  String get score => 'Score';

  @override
  String get theSolution => 'La solution';

  @override
  String get playAgain => 'Rejouer';

  @override
  String get challengeNotFound => 'Défi introuvable';

  @override
  String get goBack => 'Retour';

  @override
  String get comments => 'Commentaires';

  @override
  String get beFirstComment => 'Sois le premier à commenter !';

  @override
  String get addComment => 'Ajoute un commentaire…';

  @override
  String get like => 'J\'aime';

  @override
  String plays(int count) {
    return '$count parties';
  }

  @override
  String hidden(int count) {
    return '$count cachés';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get systemDefault => 'Langue du système';

  @override
  String get content => 'Contenu';

  @override
  String get characterPacks => 'Packs de personnages';

  @override
  String get achievements => 'Succès';

  @override
  String get account => 'Compte';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String level(int level) {
    return 'Niveau $level';
  }

  @override
  String xpValue(int xp) {
    return '$xp XP';
  }

  @override
  String toNextLevel(int percent, int next) {
    return '$percent% jusqu\'au niveau $next';
  }

  @override
  String get created => 'Créés';

  @override
  String get solved => 'Résolus';

  @override
  String get dayStreak => 'Jours de série';

  @override
  String get badges => 'Badges';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get yourChallenges => 'Tes défis';

  @override
  String get noChallengesYet => 'Aucun défi créé pour l\'instant.';

  @override
  String get rankings => 'Classements';

  @override
  String get topPlayers => 'Meilleurs joueurs';

  @override
  String get creators => 'Créateurs';

  @override
  String get premiumTitle => 'Inkognito Premium';

  @override
  String get unlockEverything => 'Débloque tout';

  @override
  String get unlockSub => 'Sans pub et avec tous les packs de créatures.';

  @override
  String get restore => 'Restaurer';

  @override
  String get goPremium => 'Passer Premium';

  @override
  String get welcomePremium => 'Bienvenue dans Premium ! 🎉';

  @override
  String get purchaseCancelled => 'Achat annulé';

  @override
  String get daily => 'Du jour';

  @override
  String get todaysPicks => 'Sélection du jour';

  @override
  String get dailySub =>
      'De nouvelles énigmes chaque jour. Garde ta série en vie !';

  @override
  String get nothingTodayTitle => 'Rien pour aujourd\'hui';

  @override
  String get nothingTodayBody => 'Reviens plus tard ou crée le premier.';

  @override
  String get discoverTitle => 'Découverte';

  @override
  String get discoverEmpty => 'Aucun dessin à trouver pour l\'instant';

  @override
  String get discoverFoundAll => 'Tout trouvé !';

  @override
  String get discoverTimeUp => 'Temps écoulé !';

  @override
  String get discoverDrawingWins => 'Ce dessin t\'a piégé';

  @override
  String get discoverSwipeNext => 'Balaye vers le haut pour le dessin suivant';

  @override
  String get nextDrawing => 'Dessin suivant';

  @override
  String tokensEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count jetons',
      one: '+1 jeton',
    );
    return '$_temp0';
  }

  @override
  String drawingRating(String stars) {
    return 'Note du dessin : $stars/5';
  }

  @override
  String get notEnoughTokensTitle => 'Pas assez de jetons';

  @override
  String notEnoughTokensBody(int cost, int balance) {
    return 'Publier un dessin coûte $cost jetons et il t\'en reste $balance. Scrolle la Découverte pour en gagner !';
  }

  @override
  String get goDiscover => 'Aller découvrir';

  @override
  String publishCost(int cost) {
    return 'Publier ($cost jetons)';
  }

  @override
  String get topDrawings => 'Dessins';

  @override
  String get noRatingYet => 'Aucun dessin noté pour l\'instant';

  @override
  String seekStats(int wins, int fails) {
    return '$wins l\'ont trouvé · $fails piégés';
  }

  @override
  String get masterpiecesTitle => 'Ou pars d\'un chef-d\'œuvre';

  @override
  String get masterpiecesSub =>
      'Des tableaux célèbres, peints dans l\'app — les fonds chargés sont les meilleures cachettes.';

  @override
  String get masterpieceStarryNight => 'La Nuit étoilée';

  @override
  String get masterpieceGreatWave => 'La Grande Vague';

  @override
  String get masterpieceWaterLilies => 'Les Nymphéas';

  @override
  String get masterpieceScream => 'Le Cri';

  @override
  String get masterpieceGrid => 'Grille colorée';

  @override
  String get masterpieceGolden => 'Jardin doré';

  @override
  String get discoverDailyBadge => 'Du jour · jetons doublés';

  @override
  String discoverComboLabel(int count) {
    return 'combo ×$count';
  }

  @override
  String get discoverTutorialTitle => 'Trouve les créatures cachées';

  @override
  String get discoverTutorialBody =>
      'Tu as quelques secondes par dessin. Touche les Inklings avant la fin du temps. Chaque dessin rapporte des jetons ; gagner en rapporte plus — et construit un combo !';

  @override
  String get discoverTutorialCta => 'C\'est parti';

  @override
  String get dailyScrollCapReached =>
      'Bonus de scroll quotidien atteint — continue de jouer pour gagner des jetons de victoire !';

  @override
  String watchAdForTokens(int count) {
    return 'Regarder une pub (+$count jetons)';
  }

  @override
  String get adNotReady =>
      'Aucune pub disponible pour l\'instant, réessaie bientôt.';

  @override
  String get likeDrawing => 'Bien caché !';

  @override
  String get reportDrawing => 'Signaler';

  @override
  String get reportSubmitted => 'Merci — on va vérifier.';

  @override
  String get reportTitle => 'Signaler ce dessin';

  @override
  String get reportBody =>
      'Dis-nous ce qui ne va pas pour que les modérateurs puissent vérifier.';

  @override
  String get reportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get reportReasonImpossible => 'Impossible à résoudre';

  @override
  String get reportReasonSpam => 'Spam ou n\'importe quoi';

  @override
  String get creatorProfile => 'Créateur';

  @override
  String creatorDrawings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dessins',
      one: '1 dessin',
    );
    return '$_temp0';
  }

  @override
  String get avgRating => 'Note moy.';

  @override
  String get followers => 'Abonnés';
}
