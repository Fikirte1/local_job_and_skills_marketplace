import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../../../models/employer_model/employer_model.dart';

class EditEmployerDocumentsScreen extends StatefulWidget {
  final Employer employer;

  const EditEmployerDocumentsScreen({super.key, required this.employer});

  @override
  State<EditEmployerDocumentsScreen> createState() => _EditEmployerDocumentsScreenState();
}

class _EditEmployerDocumentsScreenState extends State<EditEmployerDocumentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  File? _documentFile;
  String? _documentType;
  bool _isUploading = false;
  bool _isPickingDocument = false;

  final List<String> _documentTypes = [
    'Business License',
    'Tax Registration',
    'Company Registration',
    'Other Legal Document'
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Documents'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),

              if (widget.employer.canUploadDocuments) ...[
                _buildDocumentTypeSection(),
                const SizedBox(height: 24),
                _buildDocumentUploadSection(),
                const SizedBox(height: 24),
              ],

              _buildCurrentDocumentInfo(),
              const SizedBox(height: 24),

              if (widget.employer.canUploadDocuments && _documentFile != null && _documentType != null)
                _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Verification',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload official documents to verify your company identity',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _documentType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _documentTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _documentType = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select document type';
            }
            return null;
          },
          hint: const Text('Select document type'),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              _documentFile == null ? 'Upload Document' : 'Document Selected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported formats: PDF, JPG, PNG',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            if (_documentFile == null)
              OutlinedButton.icon(
                onPressed: _isPickingDocument ? null : _pickDocument,
                icon: const Icon(Icons.attach_file),
                label: const Text('Select Document'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              )
            else
              Column(
                children: [
                  Text(
                    _documentFile!.path.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _isPickingDocument ? null : _pickDocument,
                        child: const Text('Change'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _documentFile = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDocumentInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Verification Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.employer.verificationStatus == 'Unverified')
              _buildStatusMessage(
                'You need to upload a verification document to get your company verified.',
                Colors.orange,
              )
            else if (widget.employer.verificationStatus == 'Pending Review')
              _buildStatusMessage(
                'Your document is under review. Please wait for the verification team to process your submission.',
                Colors.blue,
              )
            else if (widget.employer.verificationStatus == 'Rejected')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusMessage(
                      'Your document was rejected. Please review the message below and upload a new document.',
                      Colors.red,
                    ),
                    if (widget.employer.verificationMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Reason: ${widget.employer.verificationMessage}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                )
              else if (widget.employer.verificationStatus == 'Verified')
                  _buildStatusMessage(
                    'Your company has been verified!',
                    Colors.green,
                    isBold: true,
                  ),

            const SizedBox(height: 16),

            if (widget.employer.identityDocumentUrl != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file, size: 36),
                title: Text(
                  widget.employer.documentType ?? 'Document',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Submitted on ${widget.employer.verificationSubmittedAt?.toLocal().toString().split(' ')[0] ?? 'Unknown date'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    _showDocumentPreview(widget.employer.identityDocumentUrl!);
                  },
                ),
              ),
            ],

            if (!widget.employer.canUploadDocuments && widget.employer.verificationStatus == 'Pending Review') ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'You cannot upload new documents while your current submission is under review.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _validateAndSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isUploading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Submit for Verification',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String message, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.employer.verificationStatus) {
      case 'Verified':
        return Colors.green;
      case 'Pending Review':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _pickDocument() async {
    setState(() {
      _isPickingDocument = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 5MB'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() {
          _documentFile = file;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking document: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingDocument = false;
        });
      }
    }
  }

  Future<void> _validateAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document to upload'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _submitDocuments();
  }

  Future<void> _submitDocuments() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading document...'),
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Upload to Firebase Storage
      final ref = _storage.ref().child('employer_documents/${user.uid}/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = ref.putFile(_documentFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore
      await _firestore.collection('employers').doc(user.uid).update({
        'identityDocumentUrl': downloadUrl,
        'documentType': _documentType,
        'verificationStatus': 'Pending Review',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'verificationMessage': null,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully! Your verification is now pending review.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Return to previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase error: ${e.message}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showDocumentPreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Document Preview'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _launchUrl(url),
                  child: const Text('View Full Document'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}