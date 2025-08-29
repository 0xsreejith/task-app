# 📱 Social Media Clone (Flutter)

A feature-rich social media application built with Flutter, GetX, and Hive. This project demonstrates modern Flutter development practices including state management, local storage, and clean architecture.

![Social Media Clone](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-8E0DFF?style=for-the-badge&logo=flutter&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-FF6B00?style=for-the-badge&logo=hive&logoColor=white)

## ✨ Features

- **User Authentication**
  - Secure login/logout
  - Persistent sessions with Hive
  - Auto-login functionality

- **Feed**
  - Infinite scroll feed
  - Like/unlike posts with animations
  - Pull-to-refresh
  - Post details with comments

- **Posts**
  - Create posts with images and captions
  - Image picking from gallery
  - Responsive post layout

- **Profile**
  - User profile with posts grid
  - Edit profile information
  - Profile statistics

- **Search**
  - Search for users and posts
  - Real-time search results

## 🛠 Tech Stack

- **Framework**: Flutter (stable)
- **State Management**: GetX
- **Local Storage**: Hive
- **Image Picker**: image_picker
- **Dependency Injection**: GetX Bindings
- **Routing**: GetX Navigation
- **UI Components**: Custom widgets with Material Design 3

## 📱 Screenshots

| Login Screen | Feed | Create Post | Profile |
|--------------|------|-------------|---------|
| <img src="screenshots/login.png" width=200> | <img src="screenshots/feed.png" width=200> | <img src="screenshots/create_post.png" width=200> | <img src="screenshots/profile.png" width=200> |

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Xcode (for emulators)
- VS Code / Android Studio (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/0xsreejith/task-app.git
   cd task-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Mock Login Credentials

- **Email**: `admin@gmail.com`
- **Password**: `Sree@2005`

> An admin user is auto-seeded on first launch.

## 🏗 Project Structure

```
lib/
├── app/
│   ├── bindings/          # Dependency injection
│   ├── controllers/       # Global controllers
│   ├── data/              # Data layer
│   │   ├── models/        # Data models
│   │   └── providers/     # Data providers
│   ├── modules/           # Feature modules
│   │   ├── auth/          # Authentication
│   │   ├── feed/          # Posts feed
│   │   ├── profile/       # User profile
│   │   ├── search/        # Search functionality
│   │   └── create_post/   # Create new posts
│   ├── routes/            # App routes
│   ├── services/          # Core services
│   ├── theme/             # App theming
│   └── widgets/           # Reusable widgets
├── main.dart              # App entry point
└── main_controller.dart   # Main controller
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# App Configuration
APP_NAME="Social Media Clone"
APP_VERSION=1.0.0

# API Configuration (if applicable in future)
# API_BASE_URL=https://api.example.com
# API_KEY=your_api_key_here
```

## 🧪 Testing

Run the following command to execute tests:

```bash
flutter test
```

## 🐛 Debugging

Common issues and solutions:

1. **Navigation Loops**
   - Perform a hot restart after clean install
   - Ensure proper route guards in `auth_middleware.dart`

2. **Missing Dependencies**
   ```bash
   flutter pub get
   flutter pub upgrade
   ```

3. **Build Failures**
   ```bash
   flutter clean
   flutter pub get
   ```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/)
- [GetX](https://pub.dev/packages/get)
- [Hive](https://pub.dev/packages/hive)

## 👨‍💻 Author

[Sreejith](https://github.com/0xsreejith)

---

<div align="center">
  Made with ❤️ using Flutter
</div>
