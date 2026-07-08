# Native setup

After running `flutter create .` to generate the `android/` and `ios/` folders,
apply the following platform configuration.

## Android — `android/app/src/main/AndroidManifest.xml`

Inside `<manifest>` (before `<application>`), so the app can query share targets:

```xml
<queries>
  <package android:name="com.instagram.android" />
  <package android:name="com.snapchat.android" />
  <package android:name="com.zhiliaoapp.musically" />
  <package android:name="com.whatsapp" />
  <intent>
    <action android:name="android.intent.action.SEND" />
    <data android:mimeType="image/*" />
  </intent>
</queries>
```

Inside the main `<activity>`, register the deep-link scheme so shared links open
the app:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="inkognito" android:host="challenge" />
</intent-filter>
<!-- Universal link served by the openChallenge Cloud Function -->
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="inkognito.page.link" />
</intent-filter>
```

Set `minSdkVersion 23` in `android/app/build.gradle` (required by Firebase Auth).
Place `google-services.json` in `android/app/`.

### AdMob (Android)

Inside `<application>` add the App ID meta-data (this is Google's public **test**
App ID — replace with your real one for release):

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713" />
```

The ad **unit** ids default to Google's test units in `lib/core/ads/ad_service.dart`;
override them for release via `--dart-define=ADMOB_BANNER=… ADMOB_INTERSTITIAL=…`.

## iOS — `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Take a photo to hide Inklings in.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Choose a photo to hide Inklings in.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save your finished challenge.</string>

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>instagram-stories</string>
  <string>snapchat</string>
  <string>snssdk1233</string>
  <string>whatsapp</string>
  <string>sms</string>
</array>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>inkognito</string></array>
  </dict>
</array>
```

Add associated domains (`applinks:inkognito.page.link`) in Xcode → Signing &
Capabilities, and place `GoogleService-Info.plist` in `ios/Runner/`.
Set the deployment target to iOS 13+.

### AdMob (iOS)

Add to `Info.plist` (Google's public **test** App ID — replace for release):

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

### Deep links

The in-app `DeepLinkListener` (wired in `app.dart` via `app_links`) handles both
`inkognito://challenge/<id>` and `https://<host>/c/<id>` and routes to the
challenge — no extra Dart wiring needed once the intent-filters / associated
domains above are in place.
