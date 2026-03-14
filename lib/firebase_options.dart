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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDVjiNd8bf9Kh3_7J93yYcgi9GU14P57o',
    authDomain: 'pizzahappyfamily-312.firebaseapp.com',
    projectId: 'pizzahappyfamily-312',
    storageBucket: 'pizzahappyfamily-312.firebasestorage.app',
    messagingSenderId: '478245902761',
    appId: '1:478245902761:web:063ac426f7243ea9a50cb8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDVjiNd8bf9Kh3_7J93yYcgi9GU14P57o',
    appId: '1:478245902761:web:063ac426f7243ea9a50cb8',
    messagingSenderId: '478245902761',
    projectId: 'pizzahappyfamily-312',
    storageBucket: 'pizzahappyfamily-312.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCDVjiNd8bf9Kh3_7J93yYcgi9GU14P57o',
    appId: '1:478245902761:web:063ac426f7243ea9a50cb8',
    messagingSenderId: '478245902761',
    projectId: 'pizzahappyfamily-312',
    storageBucket: 'pizzahappyfamily-312.firebasestorage.app',
  );
}
