import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/comment_model.dart' as comment_model;
import 'package:socialmedia_clone/app/widgets/loading_indicator.dart';
import '../controllers/comments_controller.dart';

class CommentsView extends GetView<CommentsController> {
  const CommentsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(child: LoadingIndicator());
              }
              
              if (controller.comments.isEmpty) {
                return const Center(
                  child: Text('No comments yet. Be the first to comment!'),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: controller.comments.length,
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return _buildCommentItem(comment);
                },
              );
            }),
          ),
          
          // Add comment input
          _buildCommentInput(),
        ],
      ),
    );
  }
  
  Widget _buildCommentItem(comment_model.Comment comment) {
    return Dismissible(
      key: ValueKey(comment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // In a real app, check if current user is the author
        final confirmed = await Get.dialog(
          AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text('Are you sure you want to delete this comment?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          await controller.deleteComment(comment.id);
        }
        return null;
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: comment.userAvatar.isNotEmpty
              ? NetworkImage(comment.userAvatar)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          comment.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.text),
            const SizedBox(height: 4),
            Text(
              comment.formattedDate,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => controller.addComment(),
            ),
          ),
          Obx(() {
            return IconButton(
              icon: controller.isPosting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.blue),
              onPressed: controller.isPosting ? null : controller.addComment,
            );
          }),
        ],
      ),
    );
  }
}
