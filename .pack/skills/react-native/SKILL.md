---
name: react-native
description: Build production React Native apps with Expo SDK 53+, Expo Router (file-based navigation), New Architecture (Fabric + TurboModules), FlashList, Reanimated 4, Zustand for state, Hermes, EAS Build, and App Store/Play Store deployment.
triggers:
  - "create a React Native app"
  - "set up navigation"
  - "optimize list performance"
  - "handle deep links"
  - "configure push notifications"
  - "deploy to stores"
  - "Expo Router"
  - "FlashList"
  - "Reanimated"
  - "Zustand"
  - "React Navigation"
  - "EAS Build"
  - "react native"
  - "expo"
  - "mobile app"
  - "iOS"
  - "Android"
  - "react-navigation"
  - "expo router"
  - "native module"
negatives:
  - "Flutter"
  - "web-only React"
  - "PWA"
  - "mobile web"
  - "Ionic"
  - "Cordova"
  - "Capacitor"
  - "Xamarin"
license: MIT
compatibility: opencode
metadata:
  workflow: mobile
  audience: developers
  version: "3.0.0"
allowed-tools:
  - bash
  - edit
  - glob
  - grep
  - read
  - write
  - websearch
  - webfetch
---


# React Native Architect

Build production React Native apps with Expo, New Architecture, and modern navigation.

## Workflow

1. **Scaffold** — `npx create-expo-app@latest MyApp --template blank-typescript`, configure SDK 53+
2. **Navigation** — Choose between Expo Router (greenfield Expo) or React Navigation v7 (bare RN / brownfield). Set up layouts, typed routes, deep linking
3. **State management** — Zustand for local client state, TanStack Query for server state. Avoid Redux unless dealing with massive synchronous state trees
4. **New Architecture** — Ensure Fabric + TurboModules enabled (default in SDK 53+). Verify third-party lib compatibility
5. **Lists** — Replace all FlatLists with FlashList from Shopify. Configure `estimatedItemSize`. Optimize `renderItem` with `React.memo`
6. **Animations** — Reanimated 4 for gesture-driven animations. Use `useSharedValue` + `useAnimatedStyle` instead of `Animated` API
7. **Images** — `expo-image` with cached, resized variants. Never bare `<Image>` without dimensions
8. **Notifications** — `expo-notifications` for push. Handle foreground, background, tap-to-navigate
9. **Performance** — Enable Hermes, lazy-load tab screens, freeze inactive screens via `react-native-screens`, `InteractionManager.runAfterInteractions` for heavy ops
10. **Ship** — `eas build --platform all --profile production`, `eas submit`, configure CI/CD with GitHub Actions

## Navigation Decision

| Scenario | Recommended |
|----------|------------|
| Greenfield Expo app | Expo Router (file-based, typed routes, deep links) |
| Bare React Native | React Navigation v7 (imperative, full control) |
| Brownfield / native modules | React Navigation v7 |
| Web + mobile | Expo Router (SSR, SEO) |

## Expo Router (file-based)

```
app/
├ _layout.tsx       # Root layout (tabs, stack)
├ index.tsx         # /
├ (tabs)/
│   ├ _layout.tsx   # Tab config
│   ├ feed.tsx      # /feed
│   └ profile.tsx   # /profile
├ product/
│   ├ [id].tsx      # /product/:id
│   └ review.tsx    # /product/:id/review
└ auth/
    ├ login.tsx     # /auth/login
    └ signup.tsx    # /auth/signup
```

Deep links work automatically. Universal links with `app.json` scheme config.

### Typed Routes (Expo Router v4+)

```typescript
// app/product/[id].tsx
import { useLocalSearchParams } from 'expo-router'

export default function ProductScreen() {
  const { id } = useLocalSearchParams<{ id: string }>()
  // id is typed as string
}
```

## React Navigation v7

```typescript
type RootStackParamList = {
  Home: undefined
  ProductDetail: { id: string }
  Cart: undefined
}

const Stack = createNativeStackNavigator<RootStackParamList>()

export function RootNavigator() {
  return (
    <NavigationContainer
      linking={{
        prefixes: ['myapp://', 'https://myapp.com'],
        config: {
          screens: {
            Home: '',
            ProductDetail: 'product/:id',
            Cart: 'cart',
          },
        },
      }}>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="ProductDetail" component={ProductDetailScreen} />
        <Stack.Screen name="Cart" component={CartScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  )
}
```

## State Management

| Scenario | Recommended |
|----------|-------------|
| Simple, small app | React Context + useState |
| Medium app | Zustand (minimal boilerplate, hooks-based) |
| Large app, complex state | Redux Toolkit (mature ecosystem, DevTools) |
| Server state | TanStack Query (caching, refetch, pagination) |

### Zustand (preferred for most apps)

```typescript
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'

interface CartStore {
  items: CartItem[]
  total: number
  addItem: (item: Product) => void
  removeItem: (id: string) => void
  clear: () => void
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],
      total: 0,
      addItem: (product) => set((state) => ({
        items: [...state.items, { ...product, quantity: 1 }],
        total: state.total + product.price,
      })),
      removeItem: (id) => set((state) => ({
        items: state.items.filter((i) => i.id !== id),
        total: state.items.filter((i) => i.id !== id).reduce((s, i) => s + i.price, 0),
      })),
      clear: () => set({ items: [], total: 0 }),
    }),
    { name: 'cart-storage', storage: createJSONStorage(() => AsyncStorage) }
  )
)
```

## Performance Rules

| Rule | Implementation |
|------|---------------|
| Enable Hermes | `hermes: true` in metro.config.js |
| Use FlashList (Shopify) | Replaces FlatList — built-in recycling, better perf |
| InteractionManager | `InteractionManager.runAfterInteractions(() => fetchData())` |
| Memoize components | `React.memo` on screen components, list items |
| Lazy load tab screens | `lazy: true` (default in Expo Router) |
| Image optimization | `expo-image` with cached, resized images |
| Avoid inline functions in render | Extract handlers, use `useCallback` |
| Freeze inactive screens | `react-native-screens` detaches from native hierarchy |

### FlashList (preferred over FlatList)

```typescript
import { FlashList } from '@shopify/flash-list'

<FlashList
  data={items}
  renderItem={renderItem}
  keyExtractor={(item) => item.id}
  estimatedItemSize={120}
/>
```

## New Architecture

Enabled by default in Expo SDK 53+.

| Component | Old | New |
|-----------|-----|-----|
| Native modules | NativeModules proxy | TurboModules (typed, synchronous) |
| View manager | Fabric not used | Fabric (synchronous rendering) |
| State updates | Bridge (async serialization) | JSI (synchronous, no serialization) |

Ensure compatibility:
```json
// app.json
{
  "expo": {
    "platforms": ["ios", "android"]
  }
}
```

## Reanimated 4

```typescript
import { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated'

export function AnimatedCard() {
  const scale = useSharedValue(1)

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }))

  return (
    <Animated.View
      style={animatedStyle}
      onTouchStart={() => { scale.value = withSpring(0.95) }}
      onTouchEnd={() => { scale.value = withSpring(1) }}
    />
  )
}
```

## Deep Linking

```json
{
  "expo": {
    "scheme": "myapp",
    "plugins": [["expo-linking"]]
  }
}
```

Always implement a fallback for malformed links.

## Push Notifications

```typescript
import * as Notifications from 'expo-notifications'

const { status } = await Notifications.requestPermissionsAsync()
if (status !== 'granted') return

const token = await Notifications.getExpoPushTokenAsync()

Notifications.addNotificationResponseReceivedListener((response) => {
  const { screen, params } = response.notification.request.content.data
  router.push({ pathname: screen as any, params: params as any })
})
```

## Deployment

```bash
eas build --platform all --profile production
eas submit --platform ios
eas submit --platform android
```

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| White screen on launch | Unhandled JS exception | Wrap root with `ErrorBoundary`, add Sentry |
| Deep link opens wrong screen | Missing or incorrect route config | Verify `app.json` scheme + linking config match |
| Push notification tap does nothing | No notification response listener | Register `addNotificationResponseReceivedListener` |
| FlashList blank / slow | Missing `estimatedItemSize` | Measure or estimate item height, pass to prop |
| Hermes crash on third-party lib | Lib not Hermes-compatible | Check lib docs, use Hermes-compatible version |
| EAS build fails on iOS | Missing provisioning profile | Run `eas credentials`, `eas device:create` |
| AsyncStorage 64KB limit on Android | Storage exceeds limit | Migrate to MMKV (react-native-mmkv) |
| Reanimated 4 worklet error | Using non-worklet code inside `useAnimatedStyle` | Only use Reanimated compatible functions inside worklets |
| TurboModule returns undefined | Fabric/TM not enabled | Verify `newArchEnabled: true` in app.json |
| Navigation state lost on restart | No persistence | Use `persistNavigationState` from expo-router or React Navigation v7 storage |

## Production Checklist

- [ ] Hermes engine enabled
- [ ] FlashList (not FlatList) for all lists
- [ ] Images use `expo-image` with resize
- [ ] `React.memo` on list items and screens
- [ ] Navigation screens lazy-loaded
- [ ] Deep linking configured and tested
- [ ] Push notifications configured
- [ ] MMKV or AsyncStorage for persistence
- [ ] Error boundary wrapping root navigator
- [ ] Sentry or similar crash reporting
- [ ] EAS Build for CI/CD
- [ ] New Architecture verified (no TurboModule issues)
- [ ] App Store / Play Store screenshots and metadata
- [ ] `InteractionManager.runAfterInteractions` for heavy operations
- [ ] `expo-constants` env segregation (dev / staging / prod)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| ScrollView for long lists | FlashList with virtualization |
| No Hermes | Enable Hermes — 2x startup improvement |
| Inline arrow functions in render | `useCallback` or extract to component |
| FlatList without optimization | Use FlashList instead |
| Deep linking as afterthought | Configure at project start |
| No error boundary | Unhandled JS error = white screen |
| `navigation.getParent()` chains | Restructure to flat navigation hierarchy |
| `setState` in navigation handlers | Navigate first, fetch on screen mount |
| Using bare `<Image>` without dimensions | `expo-image` with explicit width/height |
| Zustand store split across 10 files | Keep logically cohesive, use slices pattern |
| New Architecture disabled by default | Enable `newArchEnabled: true` in app.json |
| Manual MethodChannel for native | Use Expo Modules API (typed, modern) |
| Ignoring platform-specific safe areas | `useSafeAreaInsets` from react-native-safe-area-context |
| `console.log` in production builds | Strip via babel plugin (`transform-remove-console`) |

## Sources

- React Native Documentation (reactnative.dev)
- Expo Documentation (docs.expo.dev)
- Expo Router Documentation
- React Navigation v7 Documentation
- Shopify FlashList (shopify.github.io/flash-list)
- Reanimated 4 Documentation (docs.swmansion.com/react-native-reanimated)
- Hermes Engine Documentation
- EAS Build Documentation
- Zustand Documentation (github.com/pmndrs/zustand)
- TanStack Query Documentation (tanstack.com/query/latest)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
