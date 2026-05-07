# The Pastry Path

The Pastry Path is a production-style Flutter + Firebase app for discovering nearby bakeries and cafes, saving favorites, viewing menus and reviews, reserving tables, exploring Google Maps markers, and reading trend analytics.

## Folder Structure

```text
lib/
  core/
    constants/
    services/
    theme/
    utils/
  data/
    models/
    repositories/
  providers/
  routes/
  screens/
    analytics/
    auth/
    bakery_details/
    favorites/
    home/
    map/
    profile/
    splash/
  widgets/
  firebase_options.dart
  main.dart
test/
  widget_test.dart
```

## Setup

1. Install Flutter and run `flutter pub get`.
2. Configure Firebase with FlutterFire: `flutterfire configure`.
3. Enable Firebase Auth email/password in Firebase Console.
4. Enable Cloud Firestore and Firebase Storage.
5. Add Google Maps keys:
   - Android: pass `GOOGLE_MAPS_API_KEY` in Gradle properties or replace the manifest placeholder.
   - Web: enable Maps JavaScript API for the Google API key in `web/index.html`.
   - iOS: replace `GoogleMapsApiKey` in `ios/Runner/Info.plist`.
6. Run: `flutter run`.

## Firebase Collections

- `users/{uid}`: profile metadata and preferences.
- `bakeries/{bakeryId}`: structured bakery records.
- `reviews/{reviewId}`: `bakeryId`, `userName`, `rating`, `comment`, `createdAt`.
- `favorites/{favoriteId}`: `userId`, `bakeryId`, `createdAt`.
- `reservations/{reservationId}`: reservation date, time slot, guests, status.

## Sample Firestore Bakery

```json
{
  "name": "Sweet Crumbs Atelier",
  "description": "A refined patisserie with plated desserts and single-origin coffee.",
  "address": "Galleria Market, Gurugram",
  "category": "Pastries",
  "mood": "Date Spot",
  "imageUrls": ["https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85"],
  "rating": 4.9,
  "reviewCount": 328,
  "popularity": 94,
  "trendingScore": 91,
  "latitude": 28.4675,
  "longitude": 77.0818,
  "openUntil": "11:00 PM",
  "menu": [
    {"name": "Pistachio Cruffin", "price": 260, "category": "Pastries", "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=85"}
  ]
}
```

## Architecture

The app separates UI, business logic, and data:

- Screens render state and route to details/reservation flows.
- Providers own app state: auth, bakery browsing, favorites, recommendations, reservations.
- Repositories isolate Firebase and fallback seeded data.
- Core services handle location and offline caching.
- Widgets provide reusable polished UI: `BakeryCard`, `FavoriteButton`, `AnimatedSearchBar`, `OfferBanner`, `RatingBadge`, `SkeletonLoader`.

## Recommendation Logic

The rule-based engine ranks bakeries with:

```text
score =
(rating * 0.4) +
(popularity * 0.2) +
(trending * 0.1) +
(userPreference * 0.2) +
(distanceWeight * 0.1)
```

User preference is based on favorite categories and visited category counts. Distance weight favors nearby bakeries but still allows highly rated trending spots to appear.

## Offline Support

`SharedPreferences` caches bakery lists, favorite IDs, visited categories, recently viewed bakeries, and remember-login preference. If Firestore is unavailable, cached data or realistic seed data is shown gracefully.

## Testing

Run:

```bash
flutter test
```

Included tests cover login validation, favorite button toggling, and recommendation ranking.

## APK Build

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The APK will be generated in `build/app/outputs/flutter-apk/`.

## Challenges Faced

- Balancing Firebase-backed production structure with offline-first demo behavior.
- Keeping maps usable while API keys are environment-specific.
- Making recommendation logic deterministic enough to test while still feeling smart in the UI.

## AI Usage Disclosure

This implementation was generated with AI assistance and then validated through dependency resolution and local test/analyzer attempts. Replace demo imagery and API placeholders before production release.
