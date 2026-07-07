// GENERATED PLACEHOLDER — replace by running `flutterfire configure`.
//
// This file lets the project compile out of the box. Before shipping, run
// `flutterfire configure` (from the FlutterFire CLI) to overwrite it with the
// real keys for your Firebase project. The dummy values below are structurally
// valid but will not connect to a live backend.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'inkognito-app',
    authDomain: 'inkognito-app.firebaseapp.com',
    storageBucket: 'inkognito-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'inkognito-app',
    storageBucket: 'inkognito-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'inkognito-app',
    storageBucket: 'inkognito-app.appspot.com',
    iosBundleId: 'app.inkognito.game',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'inkognito-app',
    storageBucket: 'inkognito-app.appspot.com',
    iosBundleId: 'app.inkognito.game',
  );
}
