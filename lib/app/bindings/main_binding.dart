import 'package:get/get.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';
import 'package:socialmedia_clone/app/middleware/auth_middleware.dart';
import 'package:socialmedia_clone/app/modules/feed/controllers/feed_controller.dart';
import 'package:socialmedia_clone/app/modules/create_post/controllers/create_post_controller.dart';
import 'package:socialmedia_clone/app/modules/profile/controllers/profile_controller.dart';

class MainBinding implements Bindings {
  @override
  void dependencies() {
    // Main controller - permanent for app lifecycle
    Get.put<MainController>(
      MainController(),
      permanent: true,
    );
    
    // Initialize FeedController
    Get.lazyPut<FeedController>(
      () => FeedController(),
      fenix: true, // Recreate when needed
    );
    
    // Initialize ProfileController
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
      fenix: true,
    );
    
    // Auth middleware
    Get.put(AuthMiddleware(), permanent: true);
    Get.lazyPut<FeedController>(
      () => FeedController(),
      fenix: true,
    );
    
    Get.lazyPut<CreatePostController>(
      () => CreatePostController(),
      fenix: true,
    );
    
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
      fenix: true,
    );
  }
}
