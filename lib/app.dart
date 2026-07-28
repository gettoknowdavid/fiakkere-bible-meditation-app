import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

class FiakKereApp extends StatelessWidget {
  const FiakKereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FiakKere',
      home: FiakKereInitializationPage(),
    );
  }
}

class FiakKereInitializationPage extends WatchingWidget {
  const FiakKereInitializationPage({super.key, this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final dbReady = isReady<DatabaseService>();
    final progress = [dbReady].where((ready) => ready).length / 1;

    if (dbReady) {
      callOnceAfterThisBuild((context) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => FiakKereHome()));
      });
    }

    return Scaffold(
      body: Padding(
        padding: const .all(8.0),
        child: Column(
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          children: [
            Center(child: CircularProgressIndicator(value: progress)),
            Text('Initializing... ${(progress * 100).toInt()}%'),
            if (dbReady) Text('✓ Database ready'),
          ],
        ),
      ),
    );
  }
}

class FiakKereHome extends WatchingWidget {
  const FiakKereHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Hello World!')));
  }
}
