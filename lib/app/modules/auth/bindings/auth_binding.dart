import 'package:get/get.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';
import 'package:socialmedia_clone/app/modules/auth/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize MainController if not already initialized
    Get.put(MainController(), permanent: true);
    
    // Initialize AuthController
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
  }
}
