import 'package:fiakkere/_shared/routing/app_route.dart';
import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

final _routerConfig = KaiselRouterConfig<AppRoute>(
  initial: const SplashRoute(),
  builder: (context, route) => switch (route) {
    SplashRoute() => const Placeholder(),
    OnboardingRoute() => const Placeholder(),
    LoginRoute() => const Placeholder(),
    ShellHost() => const Placeholder(),
    SessionPlayer(:final playlistId) => Placeholder(),
  },
  pageWrapper: _rootPageWrapper,
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _routerConfig);
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
