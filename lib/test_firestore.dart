import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final snapshot = await FirebaseFirestore.instance
      .collection('locations')
      .where('destinationId', isEqualTo: 'da-lat')
      .get();

  final data = snapshot.docs
      .map((d) => {'id': d.id, 'name': d.data()['name']})
      .toList();
  print('RESULT_JSON: ${jsonEncode(data)}');
}
