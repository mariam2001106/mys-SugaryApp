import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mysugaryapp/main.dart';

class FirebaseApi {

  //instense of firebase messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  //function intaliaze notification
  Future<void> intNotification() async{
    //request premision from the user (promot the user to allow notification)
    await _firebaseMessaging.requestPermission();
    //fech the token for this device
    final FMCToken = await _firebaseMessaging.getToken();
    //print the token (for testing purposes)
    print('firebase messaging token is : $FMCToken');

    //initialize further settings for push notification
     initPushNotification();
  }

  //function to handel reseved messages
  void handelMessage(RemoteMessage? message) {
    //if the message is null
    if (message == null) return;

    //if message contains notification and user taps on the notification
    navigatorkey.currentState?.pushNamed('/remainders',
    arguments: {
      'title': message.notification?.title,
      'body': message.notification?.body,
    }
    );
  }

  //function to inatialize backgrond settings
  Future<void> initPushNotification() async {
    //handel the message when the app was terminated and now opne
    FirebaseMessaging.instance
        .getInitialMessage()
        .then(handelMessage);
    //attach a eventlistener for when the notification opnes the app 
    FirebaseMessaging.onMessageOpenedApp.listen(handelMessage);
    
  }
}