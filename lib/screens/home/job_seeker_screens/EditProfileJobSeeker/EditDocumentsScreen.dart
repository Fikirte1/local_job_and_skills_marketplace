import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';

class EditDocumentsScreen extends StatefulWidget {
  final JobSeeker jobSeeker;

  const EditDocumentsScreen({super.key, required this.jobSeeker});

  @override
  State<EditDocumentsScreen> createState() => _EditDocumentsScreenState();
}

class _EditDocumentsScreenState extends State<EditDocumentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _uploadResume() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorSnackbar('Please sign in to upload documents');
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
        dialogTitle: 'Select Your Resume',
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Enhanced file validation
      if (file.size > 5 * 1024 * 1024) {
        _showErrorSnackbar('File size must be less than 5MB');
        return;
      }

      if (!['pdf'].contains(file.extension?.toLowerCase())) {
        _showErrorSnackbar('Please upload a PDF document');
        return;
      }

      final Uint8List? fileBytes = file.bytes;
      if (fileBytes == null) {
        _showErrorSnackbar('Failed to read file content');
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Delete old resume if exists
      if (widget.jobSeeker.resumeUrl != null) {
        try {
          final oldRef = _storage.refFromURL(widget.jobSeeker.resumeUrl!);
          await oldRef.delete();
        } catch (e) {
          debugPrint('Error deleting old resume: $e');
        }
      }

      // Upload new resume with progress tracking
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'resume_${user.uid}_$timestamp.${file.extension}';
      final ref = _storage.ref().child('resumes/${user.uid}/$fileName');

      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'application/${file.extension}'),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('jobSeekers').doc(user.uid).update({
        'resumeUrl': downloadUrl,
        'resumeLastUpdated': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackbar('Resume uploaded successfully!');
    } on FirebaseException catch (e) {
      _showErrorSnackbar('Upload failed: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred');
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _deleteResume() async {
    try {
      final user = _auth.currentUser;
      if (user == null || widget.jobSeeker.resumeUrl == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('This will permanently remove your resume. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isUploading = true);

      final ref = _storage.refFromURL(widget.jobSeeker.resumeUrl!);
      await ref.delete();

      await _firestore.collection('jobSeekers').doc(user.uid).update({
        'resumeUrl': null,
        'resumeLastUpdated': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackbar('Resume deleted successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to delete resume: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _viewResume() async {
    final url = widget.jobSeeker.resumeUrl;

    if (url == null || url.isEmpty) {
      _showErrorSnackbar('No resume available to view');
      return;
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
        );
      } else {
        _showErrorSnackbar('Could not open the resume');
      }
    } catch (e) {
      _showErrorSnackbar('Error opening resume: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Resume'),
        centerTitle: true,
        actions: [
          if (widget.jobSeeker.resumeUrl != null)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: _viewResume,
              tooltip: 'View Resume',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadCard(theme, isDarkMode),
            const SizedBox(height: 24),
            _buildInstructionsCard(theme),
            if (_isUploading) _buildUploadProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/document.svg',
                  width: 24,
                  height: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Resume',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (widget.jobSeeker.resumeUrl == null)
              _buildEmptyState(theme)
            else
              _buildResumePreview(theme),
            const SizedBox(height: 16),
            _buildUploadButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 60,
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'No resume uploaded yet',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildResumePreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume.pdf',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ready to share with employers',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            onPressed: _isUploading ? null : _deleteResume,
            tooltip: 'Delete Resume',
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.upload_file),
        label: Text(
          widget.jobSeeker.resumeUrl == null
              ? 'Upload Resume'
              : 'Update Resume',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _isUploading ? null : _uploadResume,
      ),
    );
  }

  Widget _buildInstructionsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume Guidelines',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildGuidelineItem(
              icon: Icons.format_size,
              text: 'PDF document format',
              theme: theme,
            ),
            _buildGuidelineItem(
              icon: Icons.storage,
              text: 'Maximum file size: 5MB',
              theme: theme,
            ),
            _buildGuidelineItem(
              icon: Icons.article,
              text: 'Include relevant work experience',
              theme: theme,
            ),
            _buildGuidelineItem(
              icon: Icons.school,
              text: 'List your education history',
              theme: theme,
            ),
            _buildGuidelineItem(
              icon: Icons.contact_page,
              text: 'Add your contact information',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}