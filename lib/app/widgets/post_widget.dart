import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';

class PostWidget extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onProfileTap;
  final bool showFullCaption;

  const PostWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onProfileTap,
    this.showFullCaption = false,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildPostImage(ThemeData theme) {
    // Handle empty or null image URL
    if (post.imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    // Handle network images (http/https)
    if (post.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: post.imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }
    
    // Handle file:// URIs
    if (post.imageUrl.startsWith('file:')) {
      try {
        return Image.file(
          File(Uri.parse(post.imageUrl).toFilePath()),
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } catch (e) {
        debugPrint('Error loading file URI: $e');
        return _buildErrorWidget();
      }
    }
    
    // Handle direct file paths
    if (post.imageUrl.startsWith('/') || post.imageUrl.startsWith('storage/')) {
      try {
        return Image.file(
          File(post.imageUrl),
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } catch (e) {
        debugPrint('Error loading file: $e');
        return _buildErrorWidget();
      }
    }
    
    // Handle legacy post_ prefixed filenames
    if (post.imageUrl.startsWith('post_')) {
      return FutureBuilder<String>(
        future: _getLocalImagePath(post.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.file(
              File(snapshot.data!), 
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            );
          }
          return _buildLoadingWidget();
        },
      );
    }
    
    // Fallback to network image if no prefix matches
    return CachedNetworkImage(
      imageUrl: post.imageUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingWidget(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  Future<String> _getLocalImagePath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$fileName';
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Colors.red),
            title: const Text('Report Post', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      height: 300,
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
  
  ImageProvider _getProfileImageProvider(String imageUrl) {
    // Handle network images
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return CachedNetworkImageProvider(
        imageUrl,
        errorListener: (err) => const Icon(Icons.error),
      );
    } 
    // Handle file paths (with or without file:// prefix)
    else if (imageUrl.startsWith('file:') || imageUrl.startsWith('/')) {
      try {
        final file = imageUrl.startsWith('file:') 
            ? File(Uri.parse(imageUrl).toFilePath())
            : File(imageUrl);
        return FileImage(file);
      } catch (e) {
        debugPrint('Error loading profile image: $e');
        // Return a transparent image provider as fallback
        return const AssetImage('assets/images/placeholder.png');
      }
    }
    
    // Fallback to a placeholder if the URL format is not recognized
    debugPrint('Unsupported profile image URL format: $imageUrl');
    return const AssetImage('assets/images/placeholder.png');
  }
  
  Widget _buildLoadingWidget() {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // User avatar
                GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: post.userAvatar.isNotEmpty
                        ? _getProfileImageProvider(post.userAvatar)
                        : null,
                    child: post.userAvatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                const SizedBox(width: 12.0),
                // Username
                Text(
                  post.username.isNotEmpty ? post.username : 'Unknown User',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // More options
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          
          // Post image
          GestureDetector(
            onDoubleTap: onLike,
            child: post.imageUrl.isNotEmpty
                ? _buildPostImage(theme)
                : Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),
          ),
          
          // Post actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Like button
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : null,
                  ),
                  onPressed: onLike,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 28,
                ),
                const SizedBox(width: 12.0),
                // Comment button
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: onComment,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 28,
                ),
                const Spacer(),
                // Save button
                const Icon(Icons.bookmark_border, size: 28),
              ],
            ),
          ),
          
          // Likes count
          if (post.likes > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${post.likes} ${post.likes == 1 ? 'like' : 'likes' }',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4.0),
          ],
          
          // Caption
          if (post.caption.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${post.username} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
                maxLines: showFullCaption ? null : 2,
                overflow: showFullCaption ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              _formatDate(post.createdAt),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12.0,
              ),
            ),
          ),
          
          // Add comment (tappable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GestureDetector(
              onTap: onComment,
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  SizedBox(width: 12.0),
                  Text(
                    'Add a comment...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
