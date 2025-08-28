import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';

class SearchController extends GetxController {
  // Use a different name to avoid conflict with Material's SearchController
  static SearchController get to => Get.find();
  final RxString _searchQuery = ''.obs;
  final RxList<UserModel> _searchUsers = <UserModel>[].obs;
  final RxList<PostModel> _searchPosts = <PostModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchType = 'users'.obs; // 'users' or 'posts'

  String get searchQuery => _searchQuery.value;
  List<UserModel> get searchUsers => _searchUsers;
  List<PostModel> get searchPosts => _searchPosts;
  bool get isLoading => _isLoading.value;
  String get searchType => _searchType.value;

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _searchUsers.clear();
      _searchPosts.clear();
    } else {
      _performSearch();
    }
  }

  void setSearchType(String type) {
    if (type == 'users' || type == 'posts') {
      _searchType.value = type;
      if (_searchQuery.isNotEmpty) {
        _performSearch();
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) return;

    _isLoading.value = true;
    
    try {
      if (_searchType.value == 'users') {
        final allUsers = await HiveService.getUsers();
        _searchUsers.value = allUsers.where((user) {
          return user.username.toLowerCase().contains(_searchQuery.value.toLowerCase());
        }).toList();
      } else {
        final allPosts = await HiveService.getPosts();
        _searchPosts.value = allPosts.where((post) {
          return post.caption.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
              post.username.toLowerCase().contains(_searchQuery.value.toLowerCase());
        }).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to perform search');
    } finally {
      _isLoading.value = false;
    }
  }

  void clearSearch() {
    _searchQuery.value = '';
    _searchUsers.clear();
    _searchPosts.clear();
  }

  @override
  void onClose() {
    _searchQuery.close();
    _searchUsers.close();
    _searchPosts.close();
    _isLoading.close();
    _searchType.close();
    super.onClose();
  }
}
