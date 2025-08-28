# Social Media Clone (Flutter)

A lightweight social media sample app built with Flutter + GetX and Hive. It demonstrates:

- Mock authentication with persistent session
- Feed with posts (image + caption)
- Like/Unlike posts with live count updates
- Create new post (pick image from gallery + caption)
- Profile page with basic details and posts
- Local storage using Hive (no backend required)

## Tech Stack

- Flutter (stable)
- State management: GetX
- Local storage: Hive + hive_flutter
- Image picking: image_picker

## Mock Login Credentials

- Email: `admin@gmail.com`
- Password: `Sree@2005`

An admin user is auto-seeded on first launch.

## Project Structure (high-level)

- `lib/main.dart`: App bootstrap, theme, routes, bindings
- `lib/app/routes`: Route table and names
- `lib/app/middleware/auth_middleware.dart`: Route guard (auth)
- `lib/app/services/hive_service.dart`: Auth/session storage (current user + users list)
- `lib/app/data/providers/local/hive_service.dart`: Legacy provider for posts/comments/settings boxes
- `lib/app/modules/*`: Feature modules (auth, feed, create_post, profile, comments, search)
  - `controllers/`: GetX controllers
  - `views/`: Screens
  - `bindings/`: DI wiring
- `lib/app/widgets`: Reusable UI widgets (post tile, inputs, buttons)

## Features

- Login (mock) with session persisted in Hive
- Auto-redirect to feed if session exists
- Feed lists posts from local Hive box
- Pull-to-refresh feed
- Like/unlike posts, stored locally
- Create post from gallery + caption (saved locally)
- Profile view shows user info and user posts

## Running the App

1. Install Flutter SDK and Android/iOS tooling
2. Fetch packages:

```
flutter pub get
```

3. Run on device/emulator:

```
flutter run
```

If you see dependency version notices, you can safely ignore them for this mock app.

## Data & Storage

- Auth/session (current user + users list): `lib/app/services/hive_service.dart`
  - Stores current user as `Map<String, dynamic>` to avoid custom Hive adapters
  - Auto-seeds admin user `admin@gmail.com`
- Posts/Comments/Settings: `lib/app/data/providers/local/hive_service.dart`
  - Opens boxes: `auth`, `users`, `app_settings`, `posts`, `comments`
  - Posts are saved as `PostModel` or JSON maps (code handles both)

## Notes

- This is a local-only demo with mock auth and local storage
- No backend service is required
- UI is kept clean and simple to focus on core flows

## Common Issues

- If you get navigation loops, perform a hot restart after clean install
- If posts don’t appear, ensure the app has gallery permission and retry creating a post

## License

MIT
