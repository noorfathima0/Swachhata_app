import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  Future<void> _resetPassword() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _loading = true);

    try {
      await auth.resetPassword(emailController.text.trim());
      setState(() => _emailSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password reset email sent"),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Don't navigate immediately, let user see success state
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF00796B);
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Forgot Password",
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Header Illustration
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      // Background Circle
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Icon
                      Positioned.fill(
                        child: Center(
                          child: Icon(
                            _emailSent
                                ? Icons.mark_email_read_rounded
                                : Icons.lock_reset_rounded,
                            size: 80,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Main Content Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _emailSent || isDarkMode
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        _emailSent ? "Check Your Email" : "Reset Password",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        _emailSent
                            ? "We've sent a password reset link to your email address. Please check your inbox and follow the instructions."
                            : "Enter your email address and we'll send you a link to reset your password.",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      if (!_emailSent)
                        // Email Input Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'you@example.com',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.black45,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.black45,
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                      if (!_emailSent) const SizedBox(height: 24),

                      if (!_emailSent)
                        // Reset Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Send Reset Link',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                      if (_emailSent)
                        // Success State
                        Column(
                          children: [
                            // Success Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 40,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Timer for auto-redirect
                            TweenAnimationBuilder<Duration>(
                              duration: const Duration(seconds: 3),
                              tween: Tween(
                                begin: const Duration(seconds: 3),
                                end: Duration.zero,
                              ),
                              builder:
                                  (
                                    BuildContext context,
                                    Duration value,
                                    Widget? child,
                                  ) {
                                    final seconds = value.inSeconds;
                                    return Text(
                                      'Redirecting in $seconds seconds...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                    );
                                  },
                            ),
                            const SizedBox(height: 32),

                            // Back to Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Back to Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (!_emailSent) const SizedBox(height: 24),

                      if (!_emailSent)
                        // Need Help Section
                        Column(
                          children: [
                            Divider(
                              color: isDarkMode
                                  ? Colors.white30
                                  : Colors.black26,
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  size: 18,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Need help? Contact support',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Bottom Navigation
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Remember your password? ',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: TextStyle(
                            color: primaryColor,
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
        ),
      ),
    );
  }
}
