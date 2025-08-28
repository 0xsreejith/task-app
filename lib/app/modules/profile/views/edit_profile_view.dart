import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socialmedia_clone/app/widgets/custom_button.dart';
import 'package:socialmedia_clone/app/widgets/custom_text_field.dart';
import '../controllers/profile_controller.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();
  File? _pickedImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<ProfileController>();
    final user = controller.user;
    if (user != null) {
      _usernameController.text = user.username;
      _bioController.text = user.bio;
      _imageUrl = user.profileImageUrl;
      
      // Pre-cache the profile image if it exists
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        try {
          if (_imageUrl!.startsWith('http')) {
            // For network images
            precacheImage(NetworkImage(_imageUrl!), context);
          } else {
            // For local files
            precacheImage(FileImage(File(_imageUrl!)), context);
          }
        } catch (e) {
          debugPrint('Error pre-caching image: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
          // Clear the cached image URL when a new image is picked
          _imageUrl = null;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<ProfileController>();
    await controller.updateProfile(
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim(),
      imageFile: _pickedImage,
    );
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (_imageUrl?.isNotEmpty ?? false)
                              ? NetworkImage(_imageUrl!)
                              : null,
                      child: _pickedImage == null && _imageUrl?.isEmpty != false
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Username
              CustomTextField(
                controller: _usernameController,
                label: 'Username',
                hintText: 'Enter your username',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Bio
              CustomTextField(
                controller: _bioController,
                label: 'Bio',
                hintText: 'Tell us about yourself',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Save button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
