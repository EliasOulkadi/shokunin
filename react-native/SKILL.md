---
name: react-native
description: Build production React Native apps with Expo SDK 53+, Expo Router (file-based navigation), New Architecture (Fabric + TurboModules), FlashList, Reanimated 4, Zustand for state, Hermes, EAS Build, and App Store/Play Store deployment. Use when user asks to create a React Native app, set up navigation, optimize list performance, handle deep links, configure push notifications, or deploy to stores. Do NOT use for Flutter (use flutter), web React, PWA, or mobile web.
license: MIT
compatibility: opencode
metadata:
  workflow: mobile
  audience: developers
  version: "2.0"
---

# React Native Architect

Build production React Native apps with Expo, New Architecture, and modern navigation.

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
- [ ] App Store / Play Store screenshots and metadata

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

## Sources

- React Native Documentation (reactnative.dev)
- Expo Documentation (docs.expo.dev)
- Expo Router Documentation
- React Navigation v7 Documentation
- Shopify FlashList (shopify.github.io/flash-list)
- Reanimated 4 Documentation
- Hermes Engine Documentation
- EAS Build Documentation
