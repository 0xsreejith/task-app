import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// Controllers
import 'package:socialmedia_clone/app/controllers/theme_controller.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';
import 'package:socialmedia_clone/app/modules/feed/controllers/feed_controller.dart';

// Views
import 'package:socialmedia_clone/app/modules/feed/views/feed_view.dart';
import 'package:socialmedia_clone/app/modules/profile/views/profile_view.dart';

// Services & Utils
import 'package:socialmedia_clone/app/services/hive_service.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart'
    as legacy_hive;
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/theme/app_theme.dart';
import 'package:socialmedia_clone/app/utils/logger.dart';

// Bindings
import 'package:socialmedia_clone/app/bindings/main_binding.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with error handling
  try {
    debugPrint('🚀 Initializing Hive...');
    await HiveService.init();
    // Initialize legacy provider for posts/comments boxes
    await legacy_hive.HiveService.init();
    debugPrint('✅ Hive initialized successfully');

    // Initialize theme controller
    Get.put(ThemeController());

    // Initialize main controller
    final mainController = Get.put(MainController());

    // Wait for initial auth check
    try {
      debugPrint('🔍 Performing initial auth check...');
      await mainController.initialAuthCheck;
      debugPrint('✅ Initial auth check completed');
    } catch (e, stackTrace) {
      debugPrint('❌ Error during initial auth check: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ Error initializing app: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize the app. Please try again later or contact support if the problem persists.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart the app
                      runApp(const MyApp());
                    },
                    child: const Text('Try Again'),
                  ),
                  ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RxBool isInitialized = false.obs;
  final RxString initialRoute = Routes.login.obs;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      if (kDebugMode) {
        print('🔍 Checking authentication status...');
      }

      // Add a small delay to ensure Hive is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));

      final user = await HiveService.getCurrentUser();

      initialRoute.value = user != null ? Routes.main : Routes.login;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking auth: $e');
      }
      // Default to login screen on error
      initialRoute.value = Routes.login;
    } finally {
      isInitialized.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!isInitialized.value) {
        return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }

      return GetMaterialApp(
        title: 'Social Media Clone',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: initialRoute.value,
        getPages: AppPages.routes,
        defaultTransition: Transition.cupertino,
        debugShowCheckedModeBanner: false,
        logWriterCallback: Logger.write,
        initialBinding: MainBinding(),
        unknownRoute: GetPage(
          name: '/not-found',
          page: () =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        ),
      );
    });
  }
}

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    final feedController = Get.put(FeedController());

    return WillPopScope(
      onWillPop: () async {
        // Prevent going back to auth screens
        return !(await Get.offAllNamed(Routes.main));
      },
      child: Scaffold(
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Load posts when switching to feed tab
          if (controller.selectedIndex.value == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              feedController.loadPosts();
            });
          }

          return IndexedStack(
            index: controller.selectedIndex.value,
            children: [const FeedView(), const ProfileView()],
          );
        }),
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeTab,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
