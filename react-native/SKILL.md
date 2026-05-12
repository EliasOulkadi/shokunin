---
name: react-native
description: Build production React Native apps with Expo Router or React Navigation, Zustand/Redux state management, Hermes engine optimization, and performance patterns. Covers navigation architecture, deep linking, FlatList optimization, native modules, EAS Build, and App Store/Play Store deployment. Use when user asks to create a React Native app, set up navigation, optimize list performance, handle deep links, configure push notifications, or deploy to stores. Triggers on "react native", "expo", "mobile app", "iOS", "Android", "react-navigation", "expo router", "native module". Do NOT use for Flutter, web React, or general mobile design.
license: MIT
compatibility: opencode
metadata:
  workflow: mobile
  audience: developers
---

Build production React Native apps. Covers navigation, state management, performance, native modules, and deployment.

## Navigation Decision

| Scenario | Recommended |
|----------|------------|
| Greenfield Expo app | Expo Router v3 (file-based, zero-config deep links) |
| Bare React Native | React Navigation v7 (imperative, full control) |
| Brownfield / native modules | React Navigation v7 |
| Web + mobile | Expo Router (SSR, SEO) |

## Core Patterns

### Expo Router (file-based)
```
app/
├ _layout.tsx       # Root layout (tabs, stack)
├ index.tsx         # / → home screen
├ (tabs)/
│   ├ _layout.tsx   # Tab configuration
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

### React Navigation v7
```typescript
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

type RootStackParamList = {
  Home: undefined;
  ProductDetail: { id: string };
  Cart: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

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
  );
}
```

## State Management Decision

| Scenario | Recommended |
|----------|-------------|
| Simple, small app | React Context + useState |
| Medium app | Zustand (minimal boilerplate, hooks-based) |
| Large app, complex state | Redux Toolkit (mature ecosystem, DevTools) |
| Server state | TanStack Query (caching, refetch, pagination) |

### Zustand (preferred for most apps)
```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface CartStore {
  items: CartItem[];
  total: number;
  addItem: (item: Product) => void;
  removeItem: (id: string) => void;
  clear: () => void;
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],
      total: 0,
      addItem: (product) =>
        set((state) => ({
          items: [...state.items, { ...product, quantity: 1 }],
          total: state.total + product.price,
        })),
      removeItem: (id) =>
        set((state) => ({
          items: state.items.filter((i) => i.id !== id),
          total: state.items
            .filter((i) => i.id !== id)
            .reduce((sum, i) => sum + i.price, 0),
        })),
      clear: () => set({ items: [], total: 0 }),
    }),
    { name: 'cart-storage', storage: createJSONStorage(() => AsyncStorage) }
  )
);
```

## Performance Rules

| Rule | Implementation |
|------|---------------|
| Enable Hermes | `hermes: true` in metro.config.js |
| Use InteractionManager | `InteractionManager.runAfterInteractions(() => fetchData())` |
| FlatList over ScrollView | `FlatList` with `getItemLayout`, `windowSize`, `removeClippedSubviews` |
| Memoize components | `React.memo` on screen components, list items |
| Lazy load tab screens | `lazy: true` (default in Expo Router) |
| Image optimization | `react-native-fast-image` with cached, resized images |
| Avoid inline functions in render | Extract handlers, use `useCallback` |
| Freeze inactive screens | `react-native-screens` detaches from native hierarchy |

### FlatList optimization
```typescript
<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={(item) => item.id}
  getItemLayout={(_, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
  windowSize={5}
  removeClippedSubviews={true}
  maxToRenderPerBatch={10}
  initialNumToRender={8}
/>
```

## Deep Linking

### Universal links (preferred over custom URL schemes)
```typescript
// app.json (Expo)
{
  "expo": {
    "scheme": "myapp",
    "plugins": [
      ["expo-linking"]
    ]
  }
}

// React Navigation config (bare RN)
const linking = {
  prefixes: ['https://myapp.com', 'myapp://'],
  config: {
    screens: {
      Home: '',
      Product: 'product/:id',
      Profile: 'user/:username',
    },
  },
};

// Always implement a fallback for malformed links
function NotFoundScreen() {
  return <Redirect href="/" />;
}
```

## Push Notifications

```typescript
import * as Notifications from 'expo-notifications';

// Request permission
const { status } = await Notifications.requestPermissionsAsync();
if (status !== 'granted') return;

// Get push token
const token = await Notifications.getExpoPushTokenAsync();

// Handle notification (foreground)
Notifications.addNotificationReceivedListener((notification) => {
  console.log('Notification:', notification);
});

// Handle notification tap (background → navigate)
Notifications.addNotificationResponseReceivedListener((response) => {
  const { screen, params } = response.notification.request.content.data;
  router.push({ pathname: screen, params });
});
```

## Deployment

### EAS Build (Expo)
```bash
eas build --platform ios --profile production
eas build --platform android --profile production
eas submit --platform ios
eas submit --platform android
```

### Fastlane (bare RN)
```ruby
lane :deploy do
  match(type: "appstore")
  build_app(scheme: "MyApp")
  upload_to_app_store
end
```

## Production Checklist

- [ ] Hermes engine enabled
- [ ] FlatList optimized (getItemLayout, windowSize, removeClippedSubviews)
- [ ] Images use `fast-image` or `expo-image` with resize
- [ ] React.memo on list items and screens
- [ ] Navigation screens lazy-loaded
- [ ] Deep linking configured and tested
- [ ] Push notifications configured
- [ ] AsyncStorage (or MMKV) for persistence
- [ ] Error boundary wrapping root navigator
- [ ] Sentry or similar crash reporting
- [ ] EAS Build or Fastlane for CI/CD
- [ ] App Store / Play Store screenshots and metadata

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| ScrollView for long lists | FlatList with virtualization |
| No Hermes | Enable Hermes — 2x startup improvement |
| Inline arrow functions in render | `useCallback` or extract to component |
| Deep linking as afterthought | Configure at project start — prevents major refactors |
| No error boundary | Unhandled JS error = white screen |
| Navigation.getParent() chains | Restructure to flat navigation hierarchy |
| setState in navigation handlers | Navigate first, fetch on screen mount |
