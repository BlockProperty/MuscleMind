import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MuscleMindApp());
}

class MuscleMindApp extends StatelessWidget {
  const MuscleMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirestorePing(),
    );
  }
}

class FirestorePing extends StatelessWidget {
  const FirestorePing({super.key});

  static const mcqCollection = 'questions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MuscleMind – Firestore Ping')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(mcqCollection).limit(1).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final keys = docs.isEmpty ? <String>[] : docs.first.data().keys.toList()..sort();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connected ✅ docs returned: ${docs.length}'),
                const SizedBox(height: 12),
                const Text('Sample doc keys:'),
                const SizedBox(height: 8),
                Text(keys.join(', '), style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
