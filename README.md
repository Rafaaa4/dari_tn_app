# Dari.tn - Flutter Real Estate Rental App

Dari.tn is a Flutter mobile app for renting houses, apartments, and studios in Tunisia. The app uses Supabase for authentication, PostgreSQL data, row level security, and live backend storage.

## Features

### Tenants
- Browse published properties.
- Search and filter by city, property type, and text.
- View property details, images, owner info, reviews, and pricing.
- Save favorite properties.
- Create reservations with automatic price calculation.
- Use simulated payment flow for demo bookings.
- View booking history.

### Owners
- Publish and edit property listings.
- Add local or network image paths for listings.
- View owner dashboard with listing stats and booking requests.
- Accept or refuse booking requests.
- Sponsor listings with demo plans.

### Admins
- View users, properties, bookings, and platform stats.
- Approve or refuse listings.
- Manage user status.

## Tech Stack

- Flutter and Dart
- Supabase Auth
- Supabase PostgreSQL
- Supabase Row Level Security
- Riverpod for state management
- GoRouter for navigation
- Material 3 UI
- Google Fonts
- Image Picker
- Cached Network Image

## Backend

All main data is stored in Supabase tables:

- `users`
- `properties`
- `property_images`
- `favorites`
- `bookings`
- `reviews`
- `sponsored_ads`

The database schema and RLS policies are in:

```text
supabase_schema.sql
```

For an existing Supabase database, do not rerun the full `CREATE TABLE` script if tables already exist. Run only the needed `ALTER TABLE`, `DROP POLICY`, and `CREATE POLICY` blocks.

## Environment Setup

Create a `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

The app loads this file in [main.dart](lib/main.dart).

## Installation

```bash
flutter pub get
flutter run
```

If the app behaves strangely after router/auth changes, use a full restart:

```bash
flutter clean
flutter pub get
flutter run
```

## Supabase Setup

1. Create a Supabase project.
2. Open Supabase SQL Editor.
3. Run `supabase_schema.sql`.
4. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to `.env`.
5. In development, you can disable email confirmation from:

```text
Supabase Dashboard -> Authentication -> Providers -> Email -> Confirm email
```

This avoids email confirmation limits while testing registrations.


Make sure each account has a matching row in `public.users` with the correct role: `tenant`, `owner`, or `admin`.

## Project Structure

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── app_router.dart
│   │   └── app_routes.dart
│   └── theme/
│       └── app_theme.dart
├── models/
│   ├── booking_model.dart
│   ├── property_model.dart
│   ├── review_model.dart
│   └── user_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── property_provider.dart
│   └── theme_provider.dart
├── repositories/
│   ├── auth_repository.dart
│   ├── booking_repository.dart
│   └── property_repository.dart
├── screens/
│   ├── admin/
│   ├── auth/
│   ├── booking/
│   ├── home/
│   ├── owner/
│   ├── profile/
│   └── property/
└── widgets/
    ├── loading_widget.dart
    ├── property_card.dart
    └── sponsored_property_card.dart
```

## Navigation

Routes are centralized in:

```text
lib/core/constants/app_routes.dart
lib/core/constants/app_router.dart
```

Use `AppRoutes` instead of hardcoded strings:

```dart
context.go(AppRoutes.home);
context.push(AppRoutes.property(propertyId));
```

This keeps navigation safer and avoids route typos.

## Common Supabase Issues

### 429 over email send rate limit

Supabase is rate-limiting auth emails. Wait a few minutes, use another test email, or disable email confirmation during development.

### Row level security error

Check that the matching RLS policy exists for the table. The main policies are included in `supabase_schema.sql`.

### Missing column in schema cache

If Supabase says a column does not exist, run the matching `ALTER TABLE` statement and refresh/restart the app.

## Current Status

Implemented:

- Supabase Auth login/register/logout
- Role-based app behavior
- Property listing and publishing
- Favorites
- Booking and mock payment
- Owner dashboard
- Sponsoring flow
- Admin dashboard
- Light/dark theme support

Planned improvements:

- Real payment integration
- Real image upload to Supabase Storage
- Push notifications
- Chat between tenant and owner
- Maps integration
- Multi-language support

## License

MIT License.
