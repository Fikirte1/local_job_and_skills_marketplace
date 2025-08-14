import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/employer_model/employer_model.dart';
import '../../../models/admin_model.dart';
import 'employers_profile_for_admins_screen.dart';

class EmployerVerificationScreen extends StatefulWidget {
  const EmployerVerificationScreen({super.key});

  @override
  State<EmployerVerificationScreen> createState() => _EmployerVerificationScreenState();
}

class _EmployerVerificationScreenState extends State<EmployerVerificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AdminModel? _currentAdmin;
  String _selectedFilter = 'Pending Review';
  bool _isLoading = false;
  bool _adminLoaded = false;
  final ValueNotifier<bool> _isRejecting = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isRejecting.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _initializeAdmin();
  }

  Future<void> _initializeAdmin() async {
    setState(() => _isLoading = true);
    try {
      await _fetchAdminData();
      if (_currentAdmin == null) {
        _showSnackBar("Admin data not found. Please contact support.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error loading admin data", isError: true);
      debugPrint("Error initializing admin: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _adminLoaded = true;
      });
    }
  }

  Future<void> _fetchAdminData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showSnackBar("No user logged in", isError: true);
      return;
    }

    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      if (doc.exists) {
        setState(() {
          _currentAdmin = AdminModel.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin data: $e");
      rethrow;
    }
  }

  Future<List<Employer>> _fetchEmployersByStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('employers')
          .where('verificationStatus', isEqualTo: status)
          .orderBy(status == 'Pending Review' ? 'verificationSubmittedAt' : 'verifiedAt',
          descending: status != 'Pending Review')
          .limit(50)
          .get();
      return querySnapshot.docs
          .map((doc) => Employer.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint("Error fetching $status employers: $e");
      _showSnackBar("Error loading $status employers", isError: true);
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVerificationStatus({
    required String employerId,
    required String verificationStatus,
    required String verificationMessage,
  }) async {
    if (!_adminLoaded || _currentAdmin == null) {
      await _initializeAdmin();
      if (_currentAdmin == null) {
        _showSnackBar("Admin privileges required", isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('employers').doc(employerId).update({
        'verificationStatus': verificationStatus,
        'verificationMessage': verificationMessage,
        'isVerified': verificationStatus == 'Approved',
        'verifiedBy': _currentAdmin!.userId,
        'verifiedByName': _currentAdmin!.name,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar(
        "Verification $verificationStatus!",
        isError: false,
        isApproved: verificationStatus == 'Approved',
      );
      setState(() {}); // Refresh UI
    } catch (e) {
      _showSnackBar("Failed to update: ${e.toString()}", isError: true);
      debugPrint("Update error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isApproved = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : isApproved
            ? Colors.green
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showVerificationDialog(Employer employer) {
    final _formKey = GlobalKey<FormState>();
    String? _selectedRejectionReason;

    // List of predefined rejection reasons
    final List<String> rejectionReasons = [
      'Document not clear/readable',
      'Document type not accepted',
      'Document expired',
      'Information mismatch',
      'Company information incomplete'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Verify ${employer.companyName}"),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (employer.identityDocumentUrl != null)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showDocumentBottomSheet(employer.identityDocumentUrl!),
                              child: Image.network(
                                employer.identityDocumentUrl!,
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Document Type: ${employer.documentType ?? 'Not specified'}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Rejection reasons dropdown (only shown when rejecting)
                      ValueListenableBuilder<bool>(
                        valueListenable: _isRejecting,
                        builder: (context, isRejecting, child) {
                          return isRejecting ? Column(
                            children: [
                              const Text(
                                "Select rejection reason:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedRejectionReason,
                                items: rejectionReasons.map((reason) {
                                  return DropdownMenuItem(
                                    value: reason,
                                    child: Text(reason),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRejectionReason = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (isRejecting && (value == null || value.isEmpty)) {
                                    return 'Please select a reason';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ) : const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _isRejecting.value = false;
                    if (!_formKey.currentState!.validate()) return;

                    Navigator.pop(context);
                    _updateVerificationStatus(
                      employerId: employer.userId,
                      verificationStatus: 'Approved',
                      verificationMessage: "Congratulations! Your employer account has been verified. You can now post jobs and access all features.",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Approve"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _isRejecting.value = true;
                    if (!_formKey.currentState!.validate()) return;
                    if (_selectedRejectionReason == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a rejection reason")));
                      return;
                    }

                    Navigator.pop(context);
                    _updateVerificationStatus(
                      employerId: employer.userId,
                      verificationStatus: 'Rejected',
                      verificationMessage: _selectedRejectionReason!,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Reject"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDocumentBottomSheet(String documentUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Document Preview",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      documentUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployerCard(Employer employer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployersProfileForAdminsScreen(employer: employer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: employer.logoUrl != null
                        ? NetworkImage(employer.logoUrl!)
                        : null,
                    child: employer.logoUrl == null
                        ? const Icon(Icons.business, color: Colors.indigo)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employer.companyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          employer.email,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          "Status: ${employer.verificationStatus}",
                          style: TextStyle(
                            color: _getStatusColor(employer.verificationStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (employer.region != null || employer.city != null)
                Text(
                  "${employer.region ?? ''}${employer.region != null && employer.city != null ? ', ' : ''}${employer.city ?? ''}",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              if (employer.industry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Industry: ${employer.industry}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 12),
              if (employer.identityDocumentUrl != null && _selectedFilter == 'Pending Review')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Identity Document:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showDocumentBottomSheet(employer.identityDocumentUrl!),
                      child: Text(
                        "View ${employer.documentType ?? 'Document'}",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showVerificationDialog(employer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Review Verification",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending Review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmployerList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Employer>>(
      future: _fetchEmployersByStatus(_selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final employers = snapshot.data ?? [];
        if (employers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedFilter == 'Pending Review'
                      ? Icons.pending_actions
                      : _selectedFilter == 'Approved'
                      ? Icons.verified
                      : Icons.block,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'Pending Review'
                      ? "No pending verifications"
                      : _selectedFilter == 'Approved'
                      ? "No verified employers"
                      : "No rejected employers",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: employers.length,
            itemBuilder: (context, index) => _buildEmployerCard(employers[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_adminLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentAdmin == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Admin Account Not Found",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text("Please contact support"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeAdmin,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Employer Verification",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
          color:Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterChip('Pending Review', Icons.pending_actions),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', Icons.verified),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', Icons.block),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildEmployerList(),
    );
  }

  Widget _buildFilterChip(String status, IconData icon) {
    return ChoiceChip(
      label: Row(
        children: [
          Icon(icon, size: 18, color: _selectedFilter == status ? Colors.white : Colors.indigo),
          const SizedBox(width: 4),
          Text(status),
        ],
      ),
      selected: _selectedFilter == status,
      selectedColor: Colors.indigo,
      labelStyle: TextStyle(
        color: _selectedFilter == status ? Colors.white : Colors.black,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = status;
        });
      },
    );
  }
}