---
name: flutter
description: Build production Flutter apps with clean architecture, Riverpod state management, GoRouter navigation, and platform-specific integration. Covers widget composition, state management (Riverpod > Bloc > Provider), Clean Architecture layering, GoRouter with deep linking, platform channels, theming, and App Store/Play Store deployment. Use when user asks to create a Flutter app, set up state management with Riverpod, design widget trees, implement navigation, or deploy to stores. Triggers on "flutter", "dart", "riverpod", "widget", "go_router", "flutter clean architecture", "mobile app flutter", "pubspec". Do NOT use for React Native, web-only React, or general mobile design.
license: MIT
compatibility: opencode
metadata:
  workflow: mobile
  audience: developers
---

Build production Flutter apps with Clean Architecture, Riverpod, GoRouter, and platform channels.

## State Management Decision

| Scenario | Recommended |
|----------|-------------|
| New project, most apps | Riverpod (async-first, testable, DI built-in) |
| Large team, strict unidirectional flow | Bloc (explicit events/states, predictable) |
| Legacy or tiny app | Provider (simple, but context-coupled) |

## Clean Architecture + Riverpod

```
lib/
├ core/
│   ├ theme/
│   ├ constants/
│   └ network/
├ features/
│  ├ auth/
│  │   ├ domain/          # Pure Dart — entities, use cases, repository contracts
│  │   │   ├ models/user.dart
│  │   │   ├ repositories/auth_repository.dart    # abstract
│  │   │   └ usecases/login.dart
│  │   ├ data/            # Implementation — API, DB, DTOs
│  │   │   ├ repositories/auth_repository_impl.dart
│  │   │   ├ datasources/auth_remote_source.dart
│  │   │   └ dtos/user_dto.dart
│  │   └ presentation/    # Riverpod providers + UI
│  │       ├ providers/auth_provider.dart
│  │       ├ screens/login_screen.dart
│  │       └ widgets/login_form.dart
│  ├ home/
│  └ profile/
└ main.dart
```

### Domain Layer (pure Dart, no Flutter imports)
```dart
// domain/models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  const User({required this.id, required this.email, required this.name});
}

// domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
  Stream<User?> authStateChanges();
}

// domain/usecases/login.dart
class Login {
  final AuthRepository repository;
  const Login(this.repository);
  Future<User> call(String email, String password) async {
    return repository.login(email, password);
  }
}
```

### Data Layer
```dart
// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource remote;
  AuthRepositoryImpl(this.remote);
  @override
  Future<User> login(String email, String password) async {
    final dto = await remote.login(email, password);
    return dto.toDomain();
  }
  // ...
}
```

### Presentation Layer (Riverpod)
```dart
// presentation/providers/auth_provider.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(AuthRemoteSource());
});

final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final loginStatusProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>((ref) {
  return LoginNotifier(ref.watch(loginProvider));
});

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final Login _login;
  LoginNotifier(this._login) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _login(email, password));
  }
}
```

```dart
// presentation/screens/login_screen.dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginStatus = ref.watch(loginStatusProvider);
    return Scaffold(
      body: loginStatus.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text('Error: $e'),
        data: (_) => LoginForm(),
      ),
    );
  }
}
```

## Navigation with GoRouter

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = ref.read(authStateProvider).value != null;
    final isLoginRoute = state.matchedLocation.startsWith('/login');
    if (!isAuthenticated && !isLoginRoute) return '/login';
    if (isAuthenticated && isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (_, state) => ProductDetailScreen(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
  ],
);

// MaterialApp.router(routerConfig: router)
```

## Performance Rules

| Rule | Implementation |
|------|---------------|
| Avoid rebuilding entire widget tree | `Consumer` at leaf level, not wrapping entire screen |
| Use `const` constructors | Every widget that can be const should be const |
| Lazy loading | `AutomaticKeepAliveClientMixin` only when needed |
| Image optimization | `cached_network_image` with resize |
| Avoid unnecessary RepaintBoundary | Only wrap heavy, isolated widgets |
| Use `ListView.builder` over `Column`+`ListView` | Builder is lazy, Column renders all children |
| Profile before optimizing | `flutter run --profile`, check DevTools |

## Platform Integration

```dart
// Method channel (iOS/Android native code)
class BatteryPlugin {
  static const _channel = MethodChannel('com.example/battery');
  static Future<int> getBatteryLevel() async {
    final level = await _channel.invokeMethod('getBatteryLevel');
    return level as int;
  }
}

// Platform-specific code
if (defaultTargetPlatform == TargetPlatform.iOS) {
  // iOS-specific
} else if (defaultTargetPlatform == TargetPlatform.android) {
  // Android-specific
}
```

## Theming

```dart
class AppTheme {
  static const _primaryColor = Color(0xFF1B365D);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
```

## Deployment

```bash
# Build
flutter build ios --release
flutter build appbundle --release  # Android
flutter build ipa --release       # iOS

# Test before release
flutter test
flutter analyze

# CI/CD with Codemagic or GitHub Actions
# codemagic.yaml or .github/workflows/flutter.yml
```

## Production Checklist

- [ ] Riverpod providers layered (domain / data / presentation)
- [ ] Domain layer has zero Flutter imports
- [ ] GoRouter with auth redirect
- [ ] Deep linking configured
- [ ] `const` constructors everywhere possible
- [ ] Images use `cached_network_image`
- [ ] `ListView.builder` / `GridView.builder` for lists
- [ ] Dart `analyze` passes with zero errors
- [ ] Tests for domain layer (fast, no Flutter)
- [ ] Widget tests for critical screens
- [ ] Platform-specific code via method channels (not conditional imports)
- [ ] CI/CD configured (Codemagic / GitHub Actions)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Business logic in widgets | Extract to Riverpod notifiers / use cases |
| Riverpod providers depending on BuildContext | Provider — no context needed |
| `ref.watch` inside callbacks | `ref.read` for one-time, `ref.watch` only in build |
| Giant Widget build methods | Extract into smaller widgets or methods |
| No error handling in AsyncValue | Handle loading/error/data states explicitly |
| `setState` for global state | Riverpod providers |
| Hardcoded strings and colors | Theme and constants |
| `runApp` without error handling | `ErrorWidget.builder` and `PlatformDispatcher.onError` |
