import 'package:fiakkere/_shared/routing/app_route.dart';
import 'package:fiakkere/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';

final _routerConfig = KaiselRouterConfig<AppRoute>(
  initial: const ShellHost(),
  builder: (context, route) => switch (route) {
    SplashRoute() => const Placeholder(),
    OnboardingRoute() => const Placeholder(),
    LoginRoute() => const Placeholder(),
    ShellHost() => const AppShell(),
    SessionPlayer(:final playlistId) => Placeholder(),
  },
  pageWrapper: _rootPageWrapper,
);

class FiakKereApp extends WatchingWidget {
  const FiakKereApp({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = watchFuture<GetIt, void>(
      (getIt) => getIt.allReady(timeout: Duration(seconds: 30)),
      initialValue: null,
      target: di,
    );

    if (snapshot.hasError) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('FiakKere')),
          body: Center(
            child: Text(
              snapshot.error?.toString() ?? "Error registering services",
            ),
          ),
        ),
      );
    }

    if (snapshot.connectionState != ConnectionState.done) {
      return MaterialApp();
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _routerConfig,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      title: 'FiakKere',
    );
  }
}

Page<Object?> _rootPageWrapper(KaiselPageWrapperContext<AppRoute> ctx) {
  return switch (ctx.route) {
    // SessionPlayer() => Trans(),
    _ => MaterialPage(
      key: ValueKey(ctx.route.props),
      name: ctx.route.routeName,
      arguments: ctx.route,
      child: ctx.child,
    ),
  };
}
