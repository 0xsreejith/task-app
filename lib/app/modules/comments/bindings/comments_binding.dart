import 'package:get/get.dart';
import '../controllers/comments_controller.dart';

class CommentsBinding extends Bindings {
  final String postId;
  
  CommentsBinding(this.postId);
  
  @override
  void dependencies() {
    Get.lazyPut<CommentsController>(
      () => CommentsController(postId),
    );
  }
}
