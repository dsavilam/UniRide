import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtDqpPZHa7aQhDSi_IoIDZYYiFFScS8yA',
    appId: '1:726906955924:android:4eebb955b61e4f83616c81',
    messagingSenderId: '726906955924',
    projectId: 'uni-ride-214d1',
    databaseURL: 'https://uni-ride-214d1-default-rtdb.firebaseio.com',
    storageBucket: 'uni-ride-214d1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBA5UhlPOBS3d6KWaVm1BQOuXCKZhxzWx0',
    appId: '1:726906955924:ios:8f88d739687eb5ea616c81',
    messagingSenderId: '726906955924',
    projectId: 'uni-ride-214d1',
    databaseURL: 'https://uni-ride-214d1-default-rtdb.firebaseio.com',
    storageBucket: 'uni-ride-214d1.firebasestorage.app',
    iosBundleId: 'com.uniride.uniRide',
  );
}
