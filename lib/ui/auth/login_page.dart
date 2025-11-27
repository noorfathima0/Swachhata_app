import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // ---------------------------
      // 🚖 DRIVER LOGIN DETECTION
      // ---------------------------
      if (email.endsWith("@driver.com")) {
        await auth.login(email, password);

        final user = auth.currentUser;
        if (user == null) throw "Driver login failed.";

        // Fetch driver from drivers collection
        final driverSnap = await FirebaseFirestore.instance
            .collection("drivers")
            .doc(user.uid)
            .get();

        if (!driverSnap.exists) {
          throw "Driver account not found in database.";
        }

        // Redirect to driver dashboard
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
        return;
      }

      // ---------------------------
      // 👤 NORMAL USER / ADMIN LOGIN
      // ---------------------------
      await auth.login(email, password);

      final user = auth.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final role = snap['role'] ?? 'user';

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      }
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
          // Header image
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 320,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: NetworkImage(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuBaBg-zsj4B2DeiX0bYke6VU92ck9qOrk8ps7ZJYbMD65NZCSgfHEdputy7A-r5UWQVh5kxPw_-ZkvCxe5rbYek6V2-B_5u_nZaXjezia5j8EgVTMhxMcoRvoFgfyHHpTcOp34QmbGLn9gY02K07UoRW0VxKWnfJjIemHamZiYNa1-11A2tDbHOuKlexzNn9zl6AvFqt2Mwbm7G17q9gZK3HKsY5e_cyE5_6aoPSXtZqmu8I1CdBb0RxUG5VD27V7M9M-ViwapmhXc",
                        ),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // Login form
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? const Color(0xFFf6f7f8)
                                : const Color(0xFF111618),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1a2a33)
                                : const Color(0xFFf0f3f4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFFa0b1b9)
                                    : const Color(0xFF617c89),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFFf6f7f8)
                                  : const Color(0xFF111618),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1a2a33)
                                : const Color(0xFFf0f3f4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: passwordController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFFa0b1b9)
                                    : const Color(0xFF617c89),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: isDarkMode
                                      ? const Color(0xFFa0b1b9)
                                      : const Color(0xFF617c89),
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFFf6f7f8)
                                  : const Color(0xFF111618),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? const Color(0xFFa0b1b9)
                                    : const Color(0xFF617c89),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Login button
                        _loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00796B),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: const Color(
                                      0xFF80CBC4,
                                    ).withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                        // Sign up link
                        const SizedBox(height: 24),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? const Color(0xFFa0b1b9)
                                    : const Color(0xFF617c89),
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/signup'),
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF00796B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
