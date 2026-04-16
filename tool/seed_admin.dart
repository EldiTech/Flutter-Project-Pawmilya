// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_enchance/firebase_options.dart';

String _requiredDefine(String value, String name) {
  if (value.isEmpty) {
    throw StateError('Missing $name (provide via --dart-define=$name=...)');
  }
  return value;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SizedBox.shrink());

  Future<void>.delayed(const Duration(milliseconds: 300), () async {
    await _seedAdmin();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
  });
}

Future<void> _seedAdmin() async {

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final adminId = 'admin_master';
  final email = _requiredDefine(
    const String.fromEnvironment('SEED_ADMIN_EMAIL'),
    'SEED_ADMIN_EMAIL',
  );
  final password = _requiredDefine(
    const String.fromEnvironment('SEED_ADMIN_PASSWORD'),
    'SEED_ADMIN_PASSWORD',
  );

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  try {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      print('SEED_FAILED: user is null');
      return;
    }

    await user.updateDisplayName('Pawmilya Admin');

    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'username': adminId,
      'realName': 'Pawmilya Admin',
      'role': 'admin',
      'isAdmin': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('ADMIN_CREATED');
    print('email: $email');
    print('adminId: $adminId');
    print('password: $password');
    print('uid: ${user.uid}');

    await auth.signOut();
  } on FirebaseAuthException catch (e) {
    print('SEED_FAILED_AUTH: ${e.code} ${e.message ?? ''}');
  } catch (e) {
    print('SEED_FAILED_UNEXPECTED: $e');
  }
}
