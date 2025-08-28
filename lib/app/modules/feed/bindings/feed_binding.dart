import 'package:get/get.dart';
import 'package:socialmedia_clone/app/modules/feed/controllers/feed_controller.dart';

class FeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedController>(
      () => FeedController(),
      fenix: true,
    );
  }
}
