import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../models/jobseeker_model.dart';
import '../models/entreprise_model.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../services/UserService.dart';
import '../theme/app_theme.dart';

class ProfileController {
  final BuildContext context;
  final Function(VoidCallback) setState;

  final UserService userService = UserService.instance;


  ProfileController(this.context, this.setState);

  bool isEditing = false;
  bool isLoading = false;
  User? user;
  JobSeeker? jobSeeker;
  Enterprise? enterprise;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController resumeUrlController;
  late TextEditingController cvDescriptionController;
  late TextEditingController companyNameController;
  late TextEditingController companyDescriptionController;

  bool get isJobSeeker => user?.role == 'job_seeker';
  bool get isEnterprise => user?.role == 'enterprise';

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('currentUserId');

    if (userId != null) {
      var user1 = await userService.getUserById(userId);

      user = user1;

      nameController = TextEditingController(text: user!.name);
      emailController = TextEditingController(text: user!.email);
      phoneController = TextEditingController(text: user!.phone ?? '');

      resumeUrlController = TextEditingController();
      cvDescriptionController = TextEditingController();
      companyNameController = TextEditingController();
      companyDescriptionController = TextEditingController();

      if (isJobSeeker) {
        jobSeeker = await userService.getJobSeekerByUserId(user!.id!);
        resumeUrlController.text = jobSeeker?.resumeUrl ?? '';
        cvDescriptionController.text = jobSeeker?.cvDescription ?? '';
      } else if (isEnterprise) {
        enterprise = await userService.getEnterpriseByUserId(user!.id!);
        companyNameController.text = enterprise?.companyName ?? '';
        companyDescriptionController.text = enterprise?.companyDescription ?? '';
      }

      setState(() {
        isLoading = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> saveChanges() async {
    setState(() => isLoading = true);

    try {
      await userService.updateUser(
        userId: user!.id!,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );

      if (isJobSeeker) {
        await userService.updateJobSeeker(
          userId: user!.id!,
          resumeUrl: resumeUrlController.text.trim(),
          cvDescription: cvDescriptionController.text.trim(),
        );
      } else if (isEnterprise) {
        await userService.updateEnterprise(
          userId: user!.id!,
          companyName: companyNameController.text.trim(),
          companyDescription: companyDescriptionController.text.trim(),
        );
      }

      setState(() {
        isEditing = false;
        isLoading = false;
      });

      showMessage('Profile updated successfully!', isError: false);

      final updatedUser = await userService.getUserByEmail(user!.email);

      if (updatedUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage('Failed to update profile: $e', isError: true);
    }
  }

  void toggleEdit() {
    if (isEditing) {
      saveChanges();
    } else {
      setState(() => isEditing = true);
    }
  }

  void deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await userService.deleteUser(user!.id!);
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              } catch (e) {
                Navigator.pop(context);
                showMessage('Failed to delete account: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.accentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }


  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    if (isJobSeeker) {
      resumeUrlController.dispose();
      cvDescriptionController.dispose();
    } else if (isEnterprise) {
      companyNameController.dispose();
      companyDescriptionController.dispose();
    }
  }


  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must not exceed 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces and special characters for validation
    String cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.length < 8) {
      return 'Phone number must be at least 8 digits';
    }
    if (cleanPhone.length > 15) {
      return 'Phone number must not exceed 15 digits';
    }
    if (!RegExp(r'^[\d+\s\-()]+$').hasMatch(value)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  String? validateResumeUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length > 500) {
      return 'URL is too long';
    }
    // Basic URL validation
    if (!RegExp(r'^https?://').hasMatch(value.trim())) {
      return 'URL must start with http:// or https://';
    }
    return null;
  }

  String? validateCvDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.trim().length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    return null;
  }

  String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company name is required';
    }
    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Company name must not exceed 100 characters';
    }
    return null;
  }

  String? validateCompanyDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.trim().length > 2000) {
      return 'Description must not exceed 2000 characters';
    }
    return null;
  }



}