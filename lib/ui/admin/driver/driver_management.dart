import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swachhata_app/services/driver_service.dart';
import 'add_driver.dart';
import 'edit_driver.dart';

class AdminDriverManagementPage extends StatelessWidget {
  const AdminDriverManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final driverService = DriverService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ------------------- NEW THEMED APP BAR -------------------
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
          "Driver Management",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
      ),

      // ------------------- MAIN BODY -------------------
      body: StreamBuilder<QuerySnapshot>(
        stream: driverService.getDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingUI();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyUI();
          }

          final drivers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final doc = drivers[index];
              final data = doc.data() as Map<String, dynamic>;

              return _driverCard(context, doc.id, data);
            },
          );
        },
      ),

      // ------------------- FLOATING ADD BUTTON -------------------
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20, right: 20),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF2C5F2D),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text(
            'Add Driver',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDriverPage()),
            );
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // DRIVER CARD DESIGN
  // ----------------------------------------------------------------------
  Widget _driverCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16),

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

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditDriverPage(driverId: id, driverData: data),
              ),
            );
          },

          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // AVATAR
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C5F2D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: Color(0xFF2C5F2D),
                  ),
                ),

                const SizedBox(width: 16),

                // DRIVER DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? "Unnamed",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['phone'] ?? '-',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Age: ${data['age']}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ARROW
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade600,
                    size: 14,
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
  // EMPTY UI
  // ----------------------------------------------------------------------
  Widget _emptyUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 70,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Drivers Added",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Add your first driver to start managing the workforce efficiently.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // LOADING UI
  // ----------------------------------------------------------------------
  Widget _loadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading Drivers...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
