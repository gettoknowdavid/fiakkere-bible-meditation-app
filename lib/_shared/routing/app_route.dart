import 'package:kaisel/kaisel.dart';

sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

final class SplashRoute extends AppRoute {
  const SplashRoute();
}

final class OnboardingRoute extends AppRoute {
  const OnboardingRoute();
}

final class ShellHost extends AppRoute {
  const ShellHost();
}

final class LoginRoute extends AppRoute {
  const LoginRoute();
}

final class SessionPlayer extends AppRoute {
  const SessionPlayer();
}
