import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String username;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3, defaultValue: '')
  final String profileImageUrl;
  
  @HiveField(4, defaultValue: '')
  final String bio;
  
  @HiveField(5, defaultValue: 0)
  final int followersCount;
  
  @HiveField(6, defaultValue: 0)
  final int followingCount;
  
  @HiveField(7, defaultValue: 0)
  final int postsCount;
  
  @HiveField(8, defaultValue: 0)
  final int createdAt;
  
  @HiveField(8, defaultValue: false)
  final bool isFollowing;
  
  @HiveField(10, defaultValue: '')
  final String password;
  
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl = '',
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.createdAt = 0,
    this.isFollowing = false,
    this.password = '',
  });
  
  // Convert from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      bio: json['bio'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
      password: json['password'] ?? '',
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isFollowing': isFollowing,
      'password': password,
    };
  }
  
  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImageUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isFollowing,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
  
  // Toggle follow status
  UserModel toggleFollow() {
    return copyWith(
      isFollowing: !isFollowing,
      followersCount: isFollowing ? followersCount - 1 : followersCount + 1,
    );
  }
}
