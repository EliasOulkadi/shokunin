---
name: flutter
description: Build production Flutter apps with Clean Architecture, Riverpod (preferred over Bloc/Provider), GoRouter navigation, Impeller rendering engine, Dart 3.7+ patterns, platform channels via Pigeon, and App Store/Play Store deployment.
triggers: ["create a Flutter app", "set up state management", "design widgets", "implement navigation", "deploy to stores", "flutter clean architecture", "riverpod", "go_router", "build flutter", "mobile app flutter", "pubspec.yaml", "flutter test", "flutter build", "platform channel", "pigeon", "impeller"]
negatives: ["React Native", "web-only React", "general mobile design", "SwiftUI", "Jetpack Compose", "Xamarin", "Ionic", "Cordova"]
license: MIT
compatibility: opencode
metadata:
  workflow: mobile
  audience: developers
  version: "4.0.0"
  author: shokunin
---


# Flutter Architect

**Widgets are functions of state. Keep them pure. Compose, don't inherit.**

Production Flutter apps with Clean Architecture, Riverpod, GoRouter, Impeller, and platform channels. Based on Flutter docs, Riverpod patterns, and production experience.

## Decision Framework

Before writing Flutter code, answer:
- Is native performance critical? (animations, camera, maps) → Flutter is a strong fit
- Is the team already experienced with Dart? → Proceed. If React/TypeScript, consider react-native skill
- Is the app content-heavy with standard platform UI? → Consider native or react-native
- Does the app need platform-specific features not available in packages? → Verify pub.dev coverage first

## Workflow

1. **Scaffold**: `dart run flutter_skeleton` or create `lib/core`, `lib/features/*/domain|data|presentation` by hand. Add Riverpod + GoRouter + Freezed deps in `pubspec.yaml`.
2. **Domain first**: Define entities, repository contracts, and use cases. Zero Flutter imports. Pure Dart with `freezed` for sealed unions.
3. **Data layer**: Implement repositories with Dio/retrofit, DTOs with `json_serializable`, and data sources. Wire up in Riverpod with `Provider<AuthRepository>`.
4. **Presentation**: Build screens and widgets with `ConsumerWidget`/`ConsumerStatefulWidget`. Wire `NotifierProvider` for each feature. Keep `ref.watch` at leaf level.
5. **Routing**: Configure GoRouter with auth redirect (`redirect` guard), nested routes per feature, and deep link patterns.
6. **Ship**: Run tests → `flutter build appbundle` / `flutter build ipa` → deploy via Codemagic or GitHub Actions. Enable Impeller on Android in `build.gradle`.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `scaffold` | Create project with folder structure and dependencies |
| `feature` | Design a feature with domain/data/presentation layers |
| `state` | Set up Riverpod providers for a feature |
| `route` | Configure GoRouter with auth guard and deep links |
| `test` | Write unit + widget + integration tests |
| `ship` | Build and deploy to App Store + Play Store |

## Architecture

```
lib/
├ core/
│   ├ theme/      # Material 3 theming
│   ├ constants/  # App-wide constants
│   └ network/    # Dio + interceptors
├ features/
│  ├ auth/
│  │   ├ domain/        # Pure Dart — entities, use cases, contracts
│  │   ├ data/          # Repo impl, API, DTOs, data sources
│  │   └ presentation/  # Riverpod providers + screens + widgets
│  ├ home/
│  └ profile/
└ main.dart
```

### Domain Layer (zero Flutter imports)

```dart
class User {
  final String id;
  final String email;
  const User({required this.id, required this.email});
}

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Stream<User?> authStateChanges();
}

class Login {
  final AuthRepository repository;
  const Login(this.repository);
  Future<User> call(String email, String password) => repository.login(email, password);
}
```

### Riverpod State Management

| Scenario | Provider |
|----------|----------|
| Most apps | Riverpod (async-first, testable, DI built-in) |
| Large team, strict unidirectional | Bloc (explicit events/states) |
| Legacy or tiny | Provider (simple, context-coupled) |

```dart
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final loginProvider = NotifierProvider<LoginNotifier, AsyncValue<void>>((ref) {
  return LoginNotifier(ref.watch(loginUseCaseProvider));
});

class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(loginProvider);
    return status.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorWidget(message: e.toString()),
      data: (_) => const LoginForm(),
    );
  }
}
```

### GoRouter with Auth Guard

```dart
final router = GoRouter(
  redirect: (context, state) {
    final isAuth = ref.read(authStateProvider).value != null;
    final isLogin = state.matchedLocation.startsWith('/login');
    if (!isAuth && !isLogin) return '/login';
    if (isAuth && isLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  ],
);
```

### Impeller

Since Flutter 3.24+, Impeller is default on iOS. On Android, opt in:
```gradle
// android/app/build.gradle
renderingEngine = "impeller"
```

Eliminates first-frame jank. Faster frame rendering. Better memory on low-end devices.

### Platform Channels via Pigeon

```dart
// battery.dart (Pigeon input)
@HostApi()
abstract class BatteryApi {
  int getBatteryLevel();
}
```
Run: `dart run pigeon --input battery.dart --dart_out lib/battery.dart`

## Performance Rules

- `const` constructors everywhere
- `Consumer` at leaf level (not entire screen)
- `ListView.builder` / `GridView.builder` (lazy)
- `cached_network_image`
- Profile: `flutter run --profile`, DevTools
- Avoid `RepaintBoundary` overuse

## Perceived Performance

Flutter renders at 60fps on most devices and 120fps on ProMotion displays. Performance perception differs:

| Technique | Perception impact | Implementation |
|-----------|------------------|----------------|
| Skeleton loaders | Feels faster than spinners. Shows structure immediately. | `shimmer` package with matching layout shape |
| `const` constructors | Widgets that never change skip rebuild entirely. Cumulative gain on deep trees. | `const Text('...')`, `const SizedBox(...)`, `const Icon(...)` |
| `extent estimation` on scrollables | Eliminates jank from recalculating item sizes during scroll. | `ListView.builder(itemExtent: 56.0, ...)` |
| `AnimatedSwitcher` vs `Visibility` | Fade transitions feel smoother than instant appear/disappear. | Wrap changing content in `AnimatedSwitcher(duration: 200ms)` |
| `RepaintBoundary` | Isolates repaint of frequently-changing widgets (timers, animations) from rest of tree. | Wrap animated clock/progress bar in `RepaintBoundary` |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| `Bad state: No element` | Empty stream/iterable accessed without check | Guard with `.isEmpty` or use `.firstOrNull` |
| `LateInitializationError` | `late` variable accessed before init | Use nullable `T?` or `StateNotifier` with initial value |
| Platform channel: `MissingPluginException` | Method not implemented on native side | Verify Pigeon codegen ran, check method name matches both sides |
| `ConcurrentModificationError` | Modifying list while iterating | Use `.toList()` to copy before mutation, or use `List.unmodifiable` |
| `type 'Null' is not a subtype of type 'String'` | JSON null from API not handled in DTO | Add `@JsonKey(defaultValue: '')` or make fields nullable, run codegen |
| GoRouter: `GoError: no routes for location` | Deep link path not registered | Add fallback redirect to `/` or register catch-all `/*` route |
| Riverpod: provider not disposed | Circular dependency between providers | Use `ref.watch` in build methods only, never in constructors. Break cycles with `Provider.autoDispose` |
| Build failed: `Could not resolve all files` (Android) | Gradle dependency conflict or outdated plugin | Run `./gradlew --refresh-dependencies`, check `build.gradle` versions match AGP requirements |

## Production Checklist

- [ ] Riverpod providers: domain → data → presentation layers
- [ ] Domain layer: zero Flutter imports
- [ ] GoRouter: auth redirect + deep linking
- [ ] Impeller enabled on Android
- [ ] `const` constructors everywhere
- [ ] Platform channels via Pigeon (not manual MethodChannel)
- [ ] Unit tests for domain layer
- [ ] Widget tests for critical screens
- [ ] CI/CD: Codemagic / GitHub Actions
- [ ] ErrorWidget.builder + PlatformDispatcher.onError
- [ ] Retry logic on network failures
- [ ] Freezed / sealed classes for state unions

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Business logic in widgets | Extract to Riverpod notifiers / use cases |
| `ref.watch` inside callbacks | `ref.read` for one-time reads |
| Giant widgets > 200 lines | Extract into smaller widgets |
| Manual MethodChannel | Pigeon for type-safe channels |
| No error handling in AsyncValue | Handle loading/error/data explicitly |
| One giant GoRouter file | Split routes into feature modules |

## Review Format (Required)

When reviewing Flutter code, use Before | After | Why format:

| Before | After | Why |
|--------|-------|-----|
| `setState(() { count++; })` in large widget | `ref.watch(counterProvider.notifier).increment()` | setState triggers full widget rebuild; Riverpod isolates state changes |
| `ListView(children: items.map((e) => Widget(e)).toList())` | `ListView.builder(itemCount: items.length, itemBuilder: (_, i) => Widget(items[i]))` | Builder lazily constructs only visible items; map builds all upfront |
| `Navigator.push(context, MaterialPageRoute(builder: (_) => Screen()))` | `context.go('/route/${id}')`  | GoRouter enables deep linking, typed params, and auth guards |

## Perceived Performance (Extended)

Flutter renders at 60fps on most devices, 120fps on ProMotion displays.

| Technique | Perception | Implementation |
|-----------|-----------|----------------|
| `const` constructors | Widgets that never change skip rebuild entirely | `const Text(...)`, `const SizedBox(...)` |
| `RepaintBoundary` | Isolates frequently-changing widgets (timers, animations) | Wrap clock/progress bar in `RepaintBoundary` |
| Skeleton loaders | Shows structure immediately (feels faster than spinners) | `shimmer` package with matching layout |
| `itemExtent` on lists | Eliminates jank from recalculating sizes during scroll | `ListView.builder(itemExtent: 56.0)` |
| `AnimatedSwitcher` | Fade transitions feel smoother than instant appear/disappear | Wrap changing content, set duration: 200ms |
| Hero animations | Create continuity between screens | `Hero(tag: 'avatar', child: ...)` on source and destination |
| Pre-cache images | Eliminates flash-of-placeholder on revisit | `precacheImage(NetworkImage(url), context)` in initState |

**Rule**: The user feels the slowest frame. Optimize for worst case, not average.

## Sources

- Flutter Documentation (flutter.dev)
- Dart 3.7 Language Tour (dart.dev)
- Riverpod Documentation (riverpod.dev)
- GoRouter Documentation
- Impeller Rendering Engine
- Pigeon Plugin

## Pre-Flight Checklist

Before submitting Flutter code:

- [ ] All widgets use `const` constructors where possible (check with `dart analyze`)
- [ ] Long lists use `ListView.builder` or `SliverList.builder`, never `ListView(children: [...])`
- [ ] `ref.watch` only in build methods; `ref.read` only in callbacks
- [ ] Routes use GoRouter typed parameters, not manual string parsing
- [ ] AsyncValue has `.when(data:, loading:, error:)` — all three branches covered
- [ ] Platform channels use Pigeon-generated code, never manual MethodChannel
- [ ] `android/app/build.gradle` has `renderingEngine = "impeller"` (Android 14+)
- [ ] No `console.log` or `print()` statements in production code
- [ ] `flutter analyze` passes with zero errors or warnings
- [ ] Tested on real Android device (not just iOS simulator or vice versa)
- [ ] App works correctly when process is killed and restarted (state restoration)
- [ ] Safe areas respected: `MediaQuery.of(context).padding` or `SafeArea` widget

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
