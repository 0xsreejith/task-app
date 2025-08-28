import 'package:hive/hive.dart';

part 'post_model.g.dart';

@HiveType(typeId: 2)
class Comment extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String username;
  
  @HiveField(3)
  final String userAvatar;
  
  @HiveField(4)
  final String text;
  
  @HiveField(5)
  final DateTime createdAt;
  
  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Convert from JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

@HiveType(typeId: 1)
class PostModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String username;
  
  @HiveField(3)
  final String userAvatar;
  
  @HiveField(4)
  final String imageUrl;
  
  @HiveField(5)
  final String caption;
  
  @HiveField(6, defaultValue: 0)
  final int likes;
  
  @HiveField(7, defaultValue: false)
  final bool isLiked;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9, defaultValue: <Comment>[])
  final List<Comment> comments;
  
  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.imageUrl,
    required this.caption,
    this.likes = 0,
    this.isLiked = false,
    DateTime? createdAt,
    List<Comment>? comments,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    comments = comments ?? [];
  
  // Convert from JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      caption: json['caption'] ?? '',
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      comments: json['comments'] != null
          ? List<Comment>.from(
              (json['comments'] as List).map((x) => Comment.fromJson(x as Map<String, dynamic>)))
          : <Comment>[],
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'comments': comments.map((x) => x.toJson()).toList(growable: false),
    };
  }
  
  // Create a copy with updated fields
  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? imageUrl,
    String? caption,
    int? likes,
    bool? isLiked,
    DateTime? createdAt,
    List<Comment>? comments,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
    );
  }
  
  // Toggle like status
  PostModel toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likes: isLiked ? likes - 1 : likes + 1,
    );
  }
  
  // Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
