import 'package:flutter/material.dart';
import '../../../services/driver_service.dart';

class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ------------------- NEW MODERN APP BAR -------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: Colors.grey.shade700,
            onPressed: () => Navigator.pop(context),
          ),
        ),

        title: Text(
          "Add Driver",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
      ),

      // ------------------- BODY -------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C5F2D).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: Color(0xFF2C5F2D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Driver Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ------------------- INPUT FIELDS -------------------
                _inputField(
                  controller: _nameController,
                  label: "Driver Name",
                  icon: Icons.person,
                  validator: (v) =>
                      v!.isEmpty ? "Please enter driver name" : null,
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone,
                  keyboard: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: _ageController,
                  label: "Age",
                  icon: Icons.cake,
                  keyboard: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Enter age" : null,
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock,
                  obscure: true,
                  validator: (v) => v!.isEmpty ? "Enter password" : null,
                ),

                const SizedBox(height: 28),

                // ------------------- SUBMIT BUTTON -------------------
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _addDriver,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Add Driver",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
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

  // ----------------------------------------------------------------------
  // REUSABLE TEXT FIELD
  // ----------------------------------------------------------------------
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2C5F2D)),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),

        // Border styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2C5F2D), width: 2),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ADD DRIVER
  // ----------------------------------------------------------------------
  Future<void> _addDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await DriverService().addDriver(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver added successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() => _loading = false);
  }
}
