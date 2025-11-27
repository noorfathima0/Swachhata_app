import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/driver_service.dart';
import 'package:intl/intl.dart';

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
    _nameController = TextEditingController(
      text: widget.driverData['name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.driverData['phone'] ?? '',
    );
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

  // ------------------ UPDATE DRIVER ------------------
  Future<void> _updateDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await DriverService().updateDriver(widget.driverId, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
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

  // ------------------ DELETE DRIVER ------------------
  Future<void> _deleteDriver() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Driver"),
        content: const Text(
          "Are you sure you want to delete this driver permanently?",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);

    try {
      await DriverService().deleteDriver(widget.driverId);

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

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.driverData['createdAt'] != null
        ? (widget.driverData['createdAt'] as Timestamp).toDate()
        : null;

    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Driver"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // DRIVER INFO CARD
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Driver Account Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // EMAIL (READ ONLY)
                      Text(
                        "Email",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      Text(
                        widget.driverData['email'] ?? "N/A",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ACCOUNT CREATED DATE
                      Text(
                        "Account Created",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // NAME
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Driver Name"),
                validator: (v) =>
                    v!.isEmpty ? "Please enter driver name" : null,
              ),
              const SizedBox(height: 15),

              // PHONE
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (v) =>
                    v!.isEmpty ? "Please enter phone number" : null,
              ),
              const SizedBox(height: 15),

              // AGE
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Please enter age" : null,
              ),

              const SizedBox(height: 30),

              // UPDATE BUTTON
              ElevatedButton(
                onPressed: _loading ? null : _updateDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),

              // DELETE BUTTON
              OutlinedButton(
                onPressed: _deleting ? null : _deleteDriver,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _deleting
                    ? const CircularProgressIndicator(color: Colors.red)
                    : const Text(
                        "Delete Driver",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
