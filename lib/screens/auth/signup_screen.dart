/*
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../home/employer_screens/employer_dashboard.dart';
import '../home/job_seeker_screens/Job_seeker_dashboard.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();

  String? _role="Job Seeker";
  bool _isSigningUp = false; // Track loading state

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _aboutMeController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate() && _role != null) {
      setState(() {
        _isSigningUp = true; // Show spinner
      });

      try {
        final skills = _skillsController.text
            .trim()
            .split(',')
            .map((skill) => skill.trim())
            .toList();

        // Create a new user with required fields
        final user = UserModel(
          userId: '', // Will be set after Firebase registration
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _role!,
          location: _locationController.text.trim(),
          skills: skills.isNotEmpty ? skills : null,
          profilePictureUrl: null,
          resumeUrl: null,
          availability: null,
          aboutMe: _aboutMeController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          isVerified: false,  // New employers are NOT verified by default
          identityDocumentUrl: null,
          verificationStatus: 'Pending', // Default status for new accounts
          verificationMessage: null,
        );

        final registeredUser = await _authService.registerUser(
          email: user.email,
          password: _passwordController.text.trim(),
          name: user.name,
          role: user.role,
          location: user.location,
          skills: user.skills,
          profilePictureUrl: user.profilePictureUrl,
          resumeUrl: user.resumeUrl,
          availability: user.availability,
          aboutMe: user.aboutMe,
          contactNumber: user.contactNumber,
        );

        if (registeredUser != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sign-up successful!")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _role == "Employer"
                  ? EmployerDashboard()
                  : JobSeekerDashboard(),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        setState(() {
          _isSigningUp = false; // Hide spinner
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please complete all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.indigo.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Create an account to get started!",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDropdown("Select Role", ["Job Seeker", "Employer"], (value) {
                        setState(() {
                          _role = value;
                        });
                      }),
                      _buildTextField(
                          _nameController,
                          _role == "Employer"
                              ? "Company Name"
                              : "Full Name",
                          _role == "Employer"
                              ? "Please enter your company name"
                              : "Please enter your full name"),
                      if (_role == "Job Seeker")
                        _buildTextField(_skillsController, "Skills (comma-separated)",
                            "Please enter your skills"),
                      _buildTextField(_emailController, "Email Address", "Please enter a valid email",
                          keyboardType: TextInputType.emailAddress),
                      _buildTextField(_passwordController, "Password",
                          "Password must be at least 6 characters", obscureText: true),
                      _buildTextField(_locationController, "Location", "Please enter your location"),
                      _buildTextField(_aboutMeController, "About Me", null),
                      _buildTextField(_contactNumberController, "Contact Number",
                          "Please enter a valid number", keyboardType: TextInputType.phone),
                      SizedBox(height: 20),
                      _isSigningUp
                          ? Center(
                        child: SpinKitCircle(
                          color: Colors.indigo.shade400,
                          size: 50.0,
                        ),
                      )
                          : SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String? validatorText,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validatorText != null
            ? (value) => value == null || value.isEmpty ? validatorText : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: _role,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? "Please select $label" : null,
      ),
    );
  }
}
*/
