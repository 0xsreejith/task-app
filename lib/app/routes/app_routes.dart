part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  
  static const main = _Paths.main;
  static const login = _Paths.login;
  static const feed = _Paths.feed;
  static const createPost = _Paths.createPost;
  static const profile = _Paths.profile;
  static const postDetail = _Paths.postDetail;
  static const editProfile = _Paths.editProfile;
  static const comments = _Paths.comments;
  static const search = _Paths.search;
}

abstract class _Paths {
  _Paths._();
  
  static const main = '/';
  static const login = '/login';
  static const feed = '/feed';
  static const createPost = '/create-post';
  static const profile = '/profile';
  static const postDetail = '/post-detail';
  static const editProfile = '/edit-profile';
  static const comments = '/comments';
  static const search = '/search';
}
