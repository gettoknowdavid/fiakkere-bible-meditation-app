import 'package:fiakkere/_shared/routing/app_route.dart';
import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';

class SplashPage extends WatchingWidget {
  const SplashPage({super.key, this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final dbReady = isReady<Database>();
    final vesresReady = isReady<ScriptureManager>();
    final progress = [dbReady, vesresReady].where((ready) => ready).length / 2;

    if (dbReady) {
      callOnceAfterThisBuild((ctx) => ctx.pushOrReplaceTop(ShellHost()));
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
