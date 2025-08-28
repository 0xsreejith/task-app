import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/modules/auth/controllers/auth_controller.dart';
import 'package:socialmedia_clone/app/widgets/custom_button.dart';
import 'package:socialmedia_clone/app/widgets/custom_text_field.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: controller.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48.0),
                // App Logo/Title
                Text(
                  'Social Media',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Connect with friends and the world around you',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48.0),
                
                // Username Field (only for signup)
                Obx(() => !controller.isLogin.value
                    ? CustomTextField(
                        controller: controller.usernameController,
                        label: 'Username',
                        prefixIcon: Icons.person_outline,
                        onChanged: (value) {
                          if (controller.formKey.currentState?.validate() ?? false) {
                            controller.formKey.currentState?.save();
                          }
                        },
                        validator: controller.validateUsername,
                      )
                    : const SizedBox.shrink()),
                if (!controller.isLogin.value) const SizedBox(height: 16.0),
                
                // Email Field
                CustomTextField(
                  controller: controller.emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  onChanged: (value) {
                    if (controller.formKey.currentState?.validate() ?? false) {
                      controller.formKey.currentState?.save();
                    }
                  },
                  validator: controller.validateEmail,
                ),
                const SizedBox(height: 16.0),
                
                // Password Field
                CustomTextField(
                  controller: controller.passwordController,
                  label: 'Password',
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  onChanged: (value) {
                    if (controller.formKey.currentState?.validate() ?? false) {
                      controller.formKey.currentState?.save();
                    }
                  },
                  validator: controller.validatePassword,
                ),
                
                // Confirm Password Field (only for signup)
                Obx(() => !controller.isLogin.value
                    ? Column(
                        children: [
                          const SizedBox(height: 16.0),
                          CustomTextField(
                            controller: controller.confirmPasswordController,
                            label: 'Confirm Password',
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            onChanged: (value) {
                              if (controller.formKey.currentState?.validate() ?? false) {
                                controller.formKey.currentState?.save();
                              }
                            },
                            validator: controller.validateConfirmPassword,
                          ),
                        ],
                      )
                    : const SizedBox.shrink()),
                const SizedBox(height: 24.0),
                
                const SizedBox(height: 24.0),
                
                // Login/Signup Button
                Obx(() => CustomButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              final form = controller.formKey.currentState;
                              if (form == null || !form.validate()) {
                                debugPrint('Form validation failed');
                                return;
                              }
                              form.save();
                              try {
                                await controller.submitForm();
                              } catch (e) {
                                debugPrint('Form submission error: $e');
                              }
                            },
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              controller.isLogin.value ? 'Log In' : 'Sign Up',
                              style: const TextStyle(fontSize: 16),
                            ),
                    )),
                const SizedBox(height: 16.0),
                
                const SizedBox(height: 16.0),
                
                // Toggle Auth Mode
                TextButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          controller.toggleAuthMode();
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Obx(() => Text(
                    controller.isLogin.value
                        ? 'Don\'t have an account? Sign up'
                        : 'Already have an account? Log in',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                ),
                const SizedBox(height: 16.0),
                
                // Divider with "or"
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16.0),
                
                // Social Login Buttons
                CustomButton.outlined(
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 12.0),
                      const Text('Continue with Google'),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                CustomButton.outlined(
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/facebook.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 12.0),
                      const Text('Continue with Facebook'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
