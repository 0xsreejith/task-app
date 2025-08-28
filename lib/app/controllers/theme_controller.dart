import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ThemeController extends GetxController {
  // 0 = system, 1 = light, 2 = dark
  final themeMode = ThemeMode.system.obs;

  ThemeMode get currentThemeMode => themeMode.value;

  void toggleTheme() {
    if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.dark;
    }
    Get.changeThemeMode(themeMode.value);
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize with system theme
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    themeMode.value = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }
}
