import 'package:fiakkere/_shared/routing/app_route.dart';
import 'package:fiakkere/app_shell.dart';
import 'package:fiakkere/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

final _routerConfig = KaiselRouterConfig<AppRoute>(
  initial: const SplashRoute(),
  builder: (context, route) => switch (route) {
    SplashRoute() => const SplashPage(),
    OnboardingRoute() => const Placeholder(),
    LoginRoute() => const Placeholder(),
    ShellHost() => const AppShell(),
    SessionPlayer() => Placeholder(),
  },
);

class FiakKereApp extends StatelessWidget {
  const FiakKereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _routerConfig,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      title: 'FiakKere',
    );
  }
}
