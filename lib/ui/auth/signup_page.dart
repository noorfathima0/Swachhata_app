import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../user/user_dashboard.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.signup(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF101c22)
          : const Color(0xFFf6f7f8),
      body: Column(
        children: [
          // Header image with gradient overlay
          Stack(
            children: [
              Container(
                height: 256,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      "https://lh3.googleusercontent.com/aida-public/AB6AXuCstg7QfeF0ufp-gL2YVraZtWfWxz5hgo31QMnthfjUjBU5zD0BcbdAoZv66Z64Y90bxqQPBEBb30auuWvKCjeeAo4GJRpAcsZNHj4paMTKqAmodjILsfVsWOe7vWXbKUVcOMORGOUvIfKp1w1BFuRD6HdUYuBXiYlE9Mesl1S_shkNuHWw_LfP3TT2duW2VsRwtkjA1UOeil16RjpOFDGBuyph2oTm2dU9-7wJU3gu7VVd2SWvxC_REN0dA5eyJ_LIwvZVe-ydHR4",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 256,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      isDarkMode
                          ? const Color(0xFF101c22)
                          : const Color(0xFFf6f7f8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Signup card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF101c22)
                          : const Color(0xFFf6f7f8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1e293b)
                                : const Color(0xFFe2e8f0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFF94a3b8)
                                    : const Color(0xFF64748b),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1e293b),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1e293b)
                                : const Color(0xFFe2e8f0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFF94a3b8)
                                    : const Color(0xFF64748b),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1e293b),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1e293b)
                                : const Color(0xFFe2e8f0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFF94a3b8)
                                    : const Color(0xFF64748b),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1e293b),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1e293b)
                                : const Color(0xFFe2e8f0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Signup button
                        _loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00796B),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                        // Login link
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFF94a3b8)
                                    : const Color(0xFF64748b),
                                fontSize: 14,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Log In',
                                  style: TextStyle(
                                    color: Color(0xFF00796B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
