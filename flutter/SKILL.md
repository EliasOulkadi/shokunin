---
name: flutter
description: Build production Flutter apps with Clean Architecture, Riverpod (preferred over Bloc/Provider), GoRouter navigation, Impeller rendering engine, Dart 3.7+ patterns, platform channels via Pigeon, and App Store/Play Store deployment. Use when user asks to create a Flutter app, set up state management, design widgets, implement navigation, or deploy to stores. Do NOT use for React Native (use react-native), web-only React, or general mobile design.
license: MIT
compatibility: opencode
metadata:
  workflow: mobile
  audience: developers
  version: "2.0"
---

# Flutter Architect

Build production Flutter apps with Clean Architecture, Riverpod, GoRouter, Impeller, and platform channels.

## State Management Decision

| Scenario | Recommended |
|----------|-------------|
| Most apps | Riverpod (async-first, testable, DI built-in) |
| Large team, strict unidirectional | Bloc (explicit events/states, predictable) |
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
│  │   ├ domain/          # Pure Dart — entities, use cases, repo contracts
│  │   │   ├ models/user.dart
│  │   │   ├ repositories/auth_repository.dart
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
  Future<User> call(String email, String password) => repository.login(email, password);
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
  @override
  Stream<User?> authStateChanges() => remote.authStateChanges();
}
```

### Presentation Layer (Riverpod)

```dart
// presentation/providers/auth_provider.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(AuthRemoteSource());
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
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/product/:id', builder: (_, state) =>
      ProductDetailScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  ],
);
```

## Impeller (rendering engine)

Since Flutter 3.24+, Impeller is the default rendering engine on iOS and
replaces Skia. On Android, opt in:

```yaml
# android/app/build.gradle
android {
  defaultConfig {
    // Enable Impeller
    renderingEngine = "impeller"
  }
}
```

Benefits:
- Eliminates skia shader compilation jank (first-frame jank gone)
- Faster frame rendering on multiple GPUs
- Better memory usage on low-end devices

## Dart 3.7+ Patterns

```dart
// Wildcard variables (Dart 3.7)
final (result, _) = await api.fetchData();

// Sealed classes for state (Dart 3.0+)
sealed class AsyncState<T> {}
class Loading<T> extends AsyncState<T> {}
class Success<T> extends AsyncState<T> { final T data; Success(this.data); }
class Error<T> extends AsyncState<T> { final String message; Error(this.message); }

// Pattern matching
switch (state) {
  case Loading(): return const Spinner();
  case Success(data: final d): return Text(d.toString());
  case Error(message: final m): return Text('Error: $m');
}

// Records
(User user, String token) loginResult = await authService.login(email, password);

// Extension types (zero-cost wrappers)
extension type Email._(String value) {
  Email(this.value) : assert(value.contains('@'));
}
```

## Platform Integration with Pigeon

Use Pigeon for type-safe platform channels (instead of manual MethodChannel):

```yaml
# pubspec.yaml
dev_dependencies:
  pigeon: ^22.0.0
```

```dart
// battery.dart (Pigeon input)
@HostApi()
abstract class BatteryApi {
  int getBatteryLevel();
  bool isCharging();
}

// Run: dart run pigeon --input battery.dart --dart_out lib/battery.dart --objc_header_out ios/Runner/battery.h --objc_source_out ios/Runner/battery.m
```

## Performance Rules

| Rule | Implementation |
|------|---------------|
| Use Consumer at leaf level | `Consumer` wrapping specific widget, not entire screen |
| `const` constructors everywhere | Every widget that can be const should be const |
| Lazy loading | `AutomaticKeepAliveClientMixin` only when needed |
| Image optimization | `cached_network_image` or `expo-image` with resize |
| ListView.builder over Column+ListView | Builder is lazy, Column renders all children |
| Profile before optimizing | `flutter run --profile`, check DevTools |
| Avoid RepaintBoundary overuse | Only wrap heavy, isolated widgets |

## Theming (Material 3)

```dart
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B365D),
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B365D),
        brightness: Brightness.dark,
      ),
    );
  }
}
```

## Testing Patterns

```dart
// Unit test domain layer (fast, no Flutter)
void main() {
  group('Login use case', () {
    test('returns User on success', () async {
      final repo = MockAuthRepository();
      when(() => repo.login(any(), any())).thenAnswer((_) async => testUser);
      final login = Login(repo);
      final result = await login('test@test.com', 'pass');
      expect(result, isA<User>());
    });
  });
}

// Widget test
void main() {
  testWidgets('shows error on failed login', (tester) async {
    await tester.pumpWidget(const LoginScreen());
    await tester.enterText(find.byKey(const Key('email')), 'bad@test.com');
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
```

## Deployment

```bash
flutter build appbundle --release   # Android
flutter build ipa --release         # iOS
flutter build web --release         # Web

# CI/CD
# eas build --platform all --profile production
# fastlane deploy
```

## Production Checklist

- [ ] Riverpod providers layered (domain / data / presentation)
- [ ] Domain layer has zero Flutter imports
- [ ] GoRouter with auth redirect
- [ ] Deep linking configured
- [ ] `const` constructors everywhere
- [ ] Images use `cached_network_image`
- [ ] `ListView.builder` / `GridView.builder` for lists
- [ ] Impeller enabled on Android
- [ ] `dart analyze` passes with zero errors
- [ ] Unit tests for domain layer
- [ ] Widget tests for critical screens
- [ ] Platform channels via Pigeon (not manual MethodChannel)
- [ ] CI/CD configured (Codemagic / GitHub Actions)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Business logic in widgets | Extract to Riverpod notifiers / use cases |
| Riverpod depending on BuildContext | Provider — no context needed |
| `ref.watch` inside callbacks | `ref.read` for one-time, `ref.watch` only in build |
| Giant widgets > 200 lines | Extract into smaller widgets |
| No error handling in AsyncValue | Handle loading/error/data states explicitly |
| `setState` for global state | Riverpod providers |
| Manual MethodChannel without types | Pigeon for type-safe platform channels |
| `runApp` without error handling | `ErrorWidget.builder` + `PlatformDispatcher.onError` |

## Sources

- Flutter Documentation (flutter.dev)
- Dart 3.7 Language Tour (dart.dev)
- Riverpod Documentation (riverpod.dev)
- GoRouter Documentation
- Impeller Rendering Engine (flutter.dev/go/impeller)
- Pigeon Plugin (pub.dev/packages/pigeon)
- Flutter Testing Documentation
- Codemagic CI/CD for Flutter
