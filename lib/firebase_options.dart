import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else if (Platform.isIOS || Platform.isMacOS) {
      return ios;
    } else if (Platform.isAndroid) {
      return android;
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBq6kynfrm4bULGjmZ7uq6wnkoPeXvnvbM",
    authDomain: "flutter-project.firebaseapp.com",
    projectId: "fresh01-fbf48",
    messagingSenderId: "1090698442808",
    appId: "1:1090698442808:android:f82bbf1876bff0d5678ecd",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBq6kynfrm4bULGjmZ7uq6wnkoPeXvnvbM",
    appId: "1:1090698442808:android:f82bbf1876bff0d5678ecd",
    messagingSenderId: "1090698442808",
    projectId: "fresh01-fbf48",
    // storageBucket: "your-ios-storage-bucket",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBq6kynfrm4bULGjmZ7uq6wnkoPeXvnvbM",
    appId: "1:1090698442808:android:f82bbf1876bff0d5678ecd",
    messagingSenderId: "1090698442808",
    projectId: "fresh01-fbf48",
    // storageBucket: "your-android-storage-bucket",
  );
}
