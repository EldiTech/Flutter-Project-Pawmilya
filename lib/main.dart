import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/pawmilya_app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(const PawmilyaApp());
}
