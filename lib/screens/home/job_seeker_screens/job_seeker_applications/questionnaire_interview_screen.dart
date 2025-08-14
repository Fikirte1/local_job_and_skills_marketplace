import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../../../models/applications_model.dart';
import '../../employer_screens/new_application_interview/interview_details_model.dart';
import '../../employer_screens/new_application_interview/interview_schedule_model.dart';


class QuestionnaireResponseScreen extends StatefulWidget {
  final ApplicationModel application;
  final InterviewSchedule schedule;
  final InterviewDetails details;

  const QuestionnaireResponseScreen({
    Key? key,
    required this.application,
    required this.schedule,
    required this.details,
  }) : super(key: key);

  @override
  State<QuestionnaireResponseScreen> createState() => _QuestionnaireResponseScreenState();
}

class _QuestionnaireResponseScreenState extends State<QuestionnaireResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  VideoPlayerController? _videoPlayerController;
  File? _videoFile;
  bool _isUploading = false;
  bool _hasSubmitted = false;
  String? _existingVideoUrl;
  double? _uploadProgress;
  String? _responseStatus;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _checkExistingResponse();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  bool _canUpload() {
    return _responseStatus == 'needsResubmission' || _responseStatus == 'pending';
  }

  Future<void> _checkExistingResponse() async {
    try {
      final responseDoc = await FirebaseFirestore.instance
          .collection('interviewResponses')
          .doc(widget.application.applicationId)
          .get();

      if (responseDoc.exists) {
        final data = responseDoc.data()!;
        setState(() {
          _responseStatus = data['status'];
          _hasSubmitted = data['status'] == 'submitted';
          _existingVideoUrl = data['videoResponseUrl'];
          _feedback = data['feedback'];
        });

        if (_existingVideoUrl != null) {
          _initializeExistingVideoPlayer(_existingVideoUrl!);
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to check existing response: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        _initializeVideoPlayer(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick video: ${e.toString()}');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        _initializeVideoPlayer(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackbar('Failed to record video: ${e.toString()}');
    }
  }

  void _initializeVideoPlayer(File file) {
    _videoPlayerController?.dispose();
    setState(() {
      _videoFile = file;
      _videoPlayerController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
        });
    });
  }

  void _initializeExistingVideoPlayer(String videoUrl) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  Future<String> _uploadVideo(File videoFile) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('interview_responses')
          .child('${widget.application.jobId}_$userId')
          .child('response_$timestamp.mp4');

      final uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          _uploadProgress = taskSnapshot.bytesTransferred.toDouble() /
              taskSnapshot.totalBytes.toDouble();
        });
      });

      final taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: ${e.toString()}');
    }
  }

  Future<void> _submitResponse() async {
    if (_videoFile == null) {
      _showErrorSnackbar('Please select or record a video response');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final videoUrl = await _uploadVideo(_videoFile!);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Update interview response
        transaction.set(
          FirebaseFirestore.instance
              .collection('interviewResponses')
              .doc(widget.application.applicationId),
          {
            'applicationId': widget.application.applicationId,
            'scheduleId': widget.schedule.scheduleId,
            'jobId': widget.schedule.jobId,
            'status': 'submitted',
            'questions': widget.details.questions,
            'deadline': Timestamp.fromDate(widget.details.responseDeadline!),
            'videoResponseUrl': videoUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'feedback': null, // Clear any previous feedback
          },
          SetOptions(merge: true),
        );

        // Update application status
        transaction.update(
          FirebaseFirestore.instance
              .collection('applications')
              .doc(widget.application.applicationId),
          {
            'status': ApplicationStatus.responseSubmitted.toString().split('.').last,
            'statusUpdatedDate': FieldValue.serverTimestamp(),
            'statusNote': 'Questionnaire response submitted',
            'resubmissionFeedback': null, // Clear resubmission feedback
          },
        );
      });

      setState(() {
        _hasSubmitted = true;
        _existingVideoUrl = videoUrl;
        _uploadProgress = null;
        _responseStatus = 'submitted';
        _feedback = null;
      });

      _showSuccessSnackbar('Response submitted successfully!');
    } catch (e) {
      _showErrorSnackbar('Failed to submit: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_responseStatus == 'needsResubmission' && _feedback != null) {
      return StatusBanner(
        message: 'Resubmission Requested: $_feedback',
        color: Colors.orange,
      );
    } else if (_hasSubmitted && _responseStatus == 'submitted') {
      return StatusBanner(
        message: 'Response submitted. Waiting for review.',
        color: Colors.blue,
      );
    } else if (widget.details.responseDeadline!.isBefore(DateTime.now())) {
      return StatusBanner(
        message: 'The deadline for submission has passed',
        color: Colors.red,
      );
    }
    return const SizedBox();
  }

  Widget _buildVideoSection() {
    if (_hasSubmitted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_videoPlayerController!),
                  VideoProgressIndicator(_videoPlayerController!, allowScrubbing: true),
                  IconButton(
                    icon: Icon(
                      _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _videoPlayerController!.value.isPlaying
                            ? _videoPlayerController!.pause()
                            : _videoPlayerController!.play();
                      });
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Resubmit Response'),
            onPressed: (_canUpload() && !_isUploading) ? _pickVideo : null,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.orange,
            ),
          ),
          if (!_canUpload())
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'You cannot resubmit until your response is reviewed.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.videocam, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No video selected'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.video_library),
                label: const Text('Select Video'),
                onPressed: (_canUpload() && !_isUploading) ? _pickVideo : null,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.videocam),
                label: const Text('Record Video'),
                onPressed: (_canUpload() && !_isUploading) ? _recordVideo : null,
              ),
            ],
          ),
          if (!_canUpload())
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Video submission is disabled until your current response is reviewed.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    }
  }


  Widget _buildQuestionsList() {
    return Card(
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
              'Questions to Answer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.details.questions!.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final question = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$index. $question',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionButton() {
    // Don't show button if deadline has passed
    if (widget.details.responseDeadline!.isBefore(DateTime.now())) {
      return const SizedBox();
    }

    // Don't show button if already submitted and no new video selected
    if (_hasSubmitted && !_canUpload()) {
      return const SizedBox();
    }


    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isUploading || _videoFile == null) ? null : _submitResponse,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isUploading
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Uploading...'),
          ],
        )
            : Text(_hasSubmitted ? 'Update Submission' : 'Submit Response'),
      ),
    );
  }

  Widget _buildDeadlineInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Response Deadline',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat.yMMMd().add_jm()
                        .format(widget.details.responseDeadline!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isUploading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interview Response'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(),
                _buildDeadlineInfo(),
                const SizedBox(height: 16),
                _buildQuestionsList(),
                const SizedBox(height: 24),
                const Text(
                  'Video Response',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Record a 3-5 minute video answering all the questions above. '
                      'Speak clearly and ensure good lighting.',
                ),
                const SizedBox(height: 16),
                _buildVideoSection(),
                const SizedBox(height: 24),
                _buildSubmissionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class StatusBanner extends StatelessWidget {
  final String message;
  final Color color;

  const StatusBanner({
    Key? key,
    required this.message,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}