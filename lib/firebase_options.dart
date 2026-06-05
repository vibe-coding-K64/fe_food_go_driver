import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '628420378856',
    projectId: 'food-go-17a5d',
    authDomain: 'food-go-17a5d.firebaseapp.com',
    databaseURL: 'https://food-go-17a5d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'food-go-17a5d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCr9eK2rGlAGrKwWLYSIvdmrzWJp74ebQo',
    appId: '1:628420378856:android:af12af71853f7011fcc95d',
    messagingSenderId: '628420378856',
    projectId: 'food-go-17a5d',
    databaseURL: 'https://food-go-17a5d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'food-go-17a5d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '628420378856',
    projectId: 'food-go-17a5d',
    databaseURL: 'https://food-go-17a5d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'food-go-17a5d.firebasestorage.app',
    iosBundleId: 'com.example.feFoodGoDriver',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '628420378856',
    projectId: 'food-go-17a5d',
    databaseURL: 'https://food-go-17a5d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'food-go-17a5d.firebasestorage.app',
    iosBundleId: 'com.example.feFoodGoDriver',
  );
}
