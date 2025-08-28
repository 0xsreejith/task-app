import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/modules/auth/bindings/auth_binding.dart';
import 'package:socialmedia_clone/app/modules/auth/views/login_view.dart';
import 'package:socialmedia_clone/app/modules/feed/bindings/feed_binding.dart';
import 'package:socialmedia_clone/app/modules/feed/views/feed_view.dart';
import 'package:socialmedia_clone/app/modules/create_post/bindings/create_post_binding.dart';
import 'package:socialmedia_clone/app/modules/create_post/views/create_post_view.dart';
import 'package:socialmedia_clone/app/modules/profile/bindings/profile_binding.dart';
import 'package:socialmedia_clone/app/modules/profile/views/profile_view.dart' show ProfileView;
import 'package:socialmedia_clone/app/modules/comments/views/comments_view.dart';
import 'package:socialmedia_clone/app/modules/comments/controllers/comments_controller.dart';
import 'package:socialmedia_clone/app/modules/search/views/search_view.dart';
import 'package:socialmedia_clone/app/modules/search/bindings/search_binding.dart';
import 'package:socialmedia_clone/app/bindings/main_binding.dart';
import 'package:socialmedia_clone/app/middleware/auth_middleware.dart';
import 'package:socialmedia_clone/main.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.login;

  static final routes = [
    GetPage(
      name: _Paths.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.main,
      page: () => MainScreen(),
      binding: MainBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.feed,
      page: () => const FeedView(),
      binding: FeedBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.createPost,
      page: () => CreatePostView(),
      binding: CreatePostBinding(),
    ),
    GetPage(
      name: _Paths.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '${_Paths.postDetail}/:id',
      page: () => ProfileView(), // TODO: Replace with PostDetailView
    ),
    GetPage(
      name: _Paths.editProfile,
      page: () => ProfileView(), // TODO: Replace with EditProfileView
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.search,
      page: () => const SearchView(),
      binding: SearchBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '${_Paths.comments}/:postId',
      page: () {
        final postId = Get.parameters['postId']!;
        return CommentsView(
          key: ValueKey('comments_$postId'),
        );
      },
      binding: BindingsBuilder(() {
        final postId = Get.parameters['postId']!;
        Get.put(CommentsController(postId));
      }),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
