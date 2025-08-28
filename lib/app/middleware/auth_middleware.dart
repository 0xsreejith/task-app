import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/services/hive_service.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    try {
      // Get current user from Hive synchronously
      final user = HiveService.getCurrentUserSync();
      final isAuthenticated = user != null;

      debugPrint(
        '🔐 AuthMiddleware: route=$route, isAuthenticated=$isAuthenticated',
      );

      // List of public routes that don't require authentication
      final publicRoutes = {Routes.login, Routes.main};

      // If user is not authenticated and trying to access protected routes
      if (!isAuthenticated) {
        if (route == null || !publicRoutes.contains(route)) {
          return const RouteSettings(name: Routes.login);
        }
        return null;
      }

      // If user is authenticated and trying to access auth routes
      if (isAuthenticated && route == Routes.login) {
        final redirectTo = Get.parameters['redirect'];
        if (redirectTo != null && redirectTo.isNotEmpty) {
          return RouteSettings(name: redirectTo);
        }
        return const RouteSettings(name: Routes.main);
      }

      return null;
    } catch (e) {
      debugPrint('AuthMiddleware error: $e');
      // In case of error, do not redirect to avoid loops
      return null;
    }
  }
}
