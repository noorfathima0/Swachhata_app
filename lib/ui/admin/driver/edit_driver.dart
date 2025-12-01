import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/driver_service.dart';

class EditDriverPage extends StatefulWidget {
  final String driverId;
  final Map<String, dynamic> driverData;

  const EditDriverPage({
    super.key,
    required this.driverId,
    required this.driverData,
  });

  @override
  State<EditDriverPage> createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;

  bool _loading = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driverData['name']);
    _phoneController = TextEditingController(text: widget.driverData['phone']);
    _ageController = TextEditingController(
      text: widget.driverData['age']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  //                       UPDATE DRIVER
  // ------------------------------------------------------------------
  Future<void> _updateDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await DriverService().updateDriver(widget.driverId, {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "age": int.tryParse(_ageController.text.trim()) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }

    setState(() => _loading = false);
  }

  // ------------------------------------------------------------------
  //                       DELETE DRIVER
  // ------------------------------------------------------------------
  Future<void> _deleteDriver() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Driver",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to permanently delete this driver?",
        ),
        actionsPadding: const EdgeInsets.all(12),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);

    try {
      final email = widget.driverData['email'] ?? '';
      final password = widget.driverData['password'] ?? '';

      if (email.isEmpty || password.isEmpty) {
        throw Exception("Driver credentials missing.");
      }

      await DriverService().deleteDriver(widget.driverId, email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver deleted successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }

    setState(() => _deleting = false);
  }

  // ------------------------------------------------------------------
  //                           UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final createdAt = widget.driverData['createdAt'] != null
        ? (widget.driverData['createdAt'] as Timestamp).toDate()
        : null;

    final createdText = createdAt != null
        ? DateFormat("dd MMM yyyy, hh:mm a").format(createdAt)
        : "Unknown";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ------------------ MODERN APP BAR ------------------
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
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        title: Text(
          "Edit Driver",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
      ),

      // ------------------ CONTENT ------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Driver Info Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5F2D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF2C5F2D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Driver Account Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _infoRow("Email", widget.driverData['email'] ?? "N/A"),
                  const SizedBox(height: 14),

                  _infoRow("Created At", createdText),
                ],
              ),
            ),

            // Form Card
            Form(
              key: _formKey,
              child: Column(
                children: [
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
                    validator: (v) =>
                        v!.isEmpty ? "Please enter phone number" : null,
                  ),
                  const SizedBox(height: 16),

                  _inputField(
                    controller: _ageController,
                    label: "Age",
                    icon: Icons.cake,
                    keyboard: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Please enter age" : null,
                  ),

                  const SizedBox(height: 28),

                  // SAVE BUTTON
                  _saveButton(),

                  const SizedBox(height: 18),

                  // DELETE BUTTON
                  _deleteButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  //                        UI COMPONENTS
  // ------------------------------------------------------------------
  Widget _infoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2C5F2D)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF2C5F2D), width: 2),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _updateDriver,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Save Changes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _deleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _deleting ? null : _deleteDriver,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _deleting
            ? const CircularProgressIndicator(color: Colors.red)
            : const Text(
                "Delete Driver",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
