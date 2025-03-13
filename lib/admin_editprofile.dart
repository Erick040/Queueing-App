import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateAdminSignUpPage extends StatefulWidget {
  const UpdateAdminSignUpPage({super.key});

  @override
  _UpdateAdminSignUpPageState createState() => _UpdateAdminSignUpPageState();
}

class _UpdateAdminSignUpPageState extends State<UpdateAdminSignUpPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final userData = await supabase
            .from('users')
            .select()
            .eq('user_id', user.id)
            .single();

        setState(() {
          usernameController.text = userData['username'] ?? '';
          emailController.text = userData['email'] ?? '';
          isLoadingData = false;
        });
      } else {
        // If no user is logged in, navigate back to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      setState(() => isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $error')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => isLoading = true);

      try {
        final user = supabase.auth.currentUser;

        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Check if password fields are filled
        final bool updatePassword = passwordController.text.isNotEmpty &&
            confirmPasswordController.text.isNotEmpty;

        // Validate that passwords match
        if (updatePassword &&
            passwordController.text != confirmPasswordController.text) {
          throw Exception('Passwords do not match');
        }

        // Update email and password if provided
        if (emailController.text != user.email || updatePassword) {
          // Update auth email and password if changed
          await supabase.auth.updateUser(
            UserAttributes(
              email: emailController.text != user.email
                  ? emailController.text
                  : null,
              password: updatePassword ? passwordController.text : null,
            ),
          );
        }

        // Update user profile data
        await supabase.from('users').update({
          'username': usernameController.text,
          'email': emailController.text,
        }).eq('user_id', user.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        setState(() => isLoading = false);
        Navigator.pop(context);
      } catch (error) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Icon(Icons.account_circle,
                          size: 100, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: usernameController,
                              label: "Username",
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: emailController,
                              label: "Email",
                              icon: Icons.email,
                            ),
                            const SizedBox(height: 10),
                            _buildPasswordField(
                              controller: passwordController,
                              label:
                                  "New Password (leave blank to keep current)",
                              isPasswordVisible: _isPasswordVisible,
                              toggleVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              required: false,
                            ),
                            const SizedBox(height: 10),
                            _buildPasswordField(
                              controller: confirmPasswordController,
                              label: "Confirm New Password",
                              isPasswordVisible: _isConfirmPasswordVisible,
                              toggleVisibility: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                              required: false,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text("Update Profile",
                                      style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(icon),
      ),
      validator: (value) => value!.isEmpty ? "Enter $label" : null,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isPasswordVisible,
    required VoidCallback toggleVisibility,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return "Enter $label";
        }
        if (value != null && value.isNotEmpty && value.length < 6) {
          return "Password too short";
        }
        return null;
      },
    );
  }
}
