import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
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
    final dbReady = isReady<Database>();
    final vesresReady = isReady<ScriptureManager>();
    final progress = [dbReady, vesresReady].where((ready) => ready).length / 2;

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
            if (vesresReady) Text('✓ Verses ready'),
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
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          children: [
            Text('Hello World!'),
            ElevatedButton(
              onPressed: () {
                final args = ScriptureArgs(book: 1, chapter: 1);
                final manager = di<ScriptureManager>();
                manager.getVersesCommand.run(args);
              },
              child: Text('Test Verses'),
            ),
          ],
        ),
      ),
    );
  }
}
