import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';
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
      
      // List of public routes that don't require authentication
      final publicRoutes = {
        Routes.login,
        // Add other public routes here
      };
      
      // If user is not authenticated and trying to access protected routes
      if (!isAuthenticated && route != null && !publicRoutes.contains(route)) {
        // Store the intended URL for redirecting back after login
        if (route.isNotEmpty && route != Routes.login) {
          Get.parameters['redirect'] = route;
        }
        return const RouteSettings(name: Routes.login);
      }
      
      // If user is authenticated and trying to access auth routes
      if (isAuthenticated && route == Routes.login) {
        // Check for redirect parameter
        final redirectTo = Get.parameters['redirect'];
        if (redirectTo != null && redirectTo.isNotEmpty) {
          return RouteSettings(name: redirectTo);
        }
        return const RouteSettings(name: Routes.main);
      }
      
      return null;
    } catch (e) {
      debugPrint('AuthMiddleware error: $e');
      // In case of error, redirect to login
      return const RouteSettings(name: Routes.login);
    }
  }
}
