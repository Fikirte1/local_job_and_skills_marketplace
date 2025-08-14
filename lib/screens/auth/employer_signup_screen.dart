import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:local_job_and_skills_marketplace/utilities/industry_data.dart';
import '../../services/auth_service.dart';
import '../../utilities/region_city_data.dart';
import '../home/employer_screens/employer_dashboard.dart';

class EmployerSignupScreen extends StatefulWidget {
  const EmployerSignupScreen({super.key});

  @override
  State<EmployerSignupScreen> createState() => _EmployerSignupScreenState();
}

class _EmployerSignupScreenState extends State<EmployerSignupScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _industryData = IndustryData();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _aboutCompanyController = TextEditingController();

  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedIndustry;
  List<String> _cities = [];
  bool _isSigningUp = false;

  List<String> get _industries => _industryData.industries;

  void _updateCities(String? region) {
    setState(() {
      _selectedRegion = region;
      _cities = region != null ? RegionCityData.regionCitiesMap[region] ?? [] : [];
      _selectedCity = null;
    });
  }

  bool _isValidEthiopianPhoneNumber(String phone) {
    final regex = RegExp(r'^[79]\d{8}$');
    return regex.hasMatch(phone);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isValidName(String name) {
    return RegExp(r'^[a-zA-Z\s]{2,}$').hasMatch(name);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords don't match")),
      );
      return;
    }

    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your region")),
      );
      return;
    }

    setState(() => _isSigningUp = true);

    try {
      final user = await _authService.registerEmployer(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        companyName: _companyNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        aboutCompany: _aboutCompanyController.text.trim(),
        region: _selectedRegion,
        city: _selectedCity,
        industry: _selectedIndustry,
      );

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmployerDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningUp = false);
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNumberController.dispose();
    _aboutCompanyController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    Widget? prefix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: prefix ?? Icon(icon),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text("Employer Registration"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Your Employer Account",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Fill in your company details to get started.",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: "Company Name",
                controller: _companyNameController,
                icon: Icons.business,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter your company name";
                  }
                  if (RegExp(r'^\d+$').hasMatch(val.trim())) {
                    return "Company name cannot be only numbers";
                  }
                  if (!RegExp(r'^[a-zA-Z0-9\s&.,-]+$').hasMatch(val.trim())) {
                    return "Invalid characters in company name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Email",
                controller: _emailController,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter your email";
                    }

                    final emailRegex = RegExp(
                        r"^[\w\.\-]+@[a-zA-Z\d\-]+\.[a-zA-Z]{2,}$"
                    );

                    if (!emailRegex.hasMatch(val.trim())) {
                      return "Enter a valid email address";
                    }

                    return null;
                  }
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Password",
                controller: _passwordController,
                icon: Icons.lock,
                obscure: true,
                validator: (val) => val == null || val.length < 6
                    ? "Password must be at least 6 characters"
                    : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Confirm Password",
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                obscure: true,
                validator: (val) => val != _passwordController.text
                    ? "Passwords don't match"
                    : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: const Text("+251", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      label: "Phone (e.g. 912345678)",
                      controller: _contactNumberController,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      prefix: null,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Enter phone number";
                        if (!_isValidEthiopianPhoneNumber(val)) return "Start with 9 or 7 and 9 digits";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: "Region",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.map),
                ),
                items: RegionCityData.regions
                    .map((region) => DropdownMenuItem(value: region, child: Text(region)))
                    .toList(),
                onChanged: _updateCities,
                validator: (val) => val == null ? "Select a region" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: "City",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: _cities
                    .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: _selectedRegion != null
                    ? (val) => setState(() => _selectedCity = val)
                    : null,
                validator: (val) => _selectedRegion != null && val == null ? "Select a city" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedIndustry,
                decoration: InputDecoration(
                  labelText: "Industry",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.work),
                ),
                items: _industries
                    .map((industry) => DropdownMenuItem(value: industry, child: Text(industry)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedIndustry = val),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "About Company",
                controller: _aboutCompanyController,
                icon: Icons.description,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Describe your company";
                  }
                  if (val.trim().length < 30) {
                    return "Please write at least 30 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSigningUp ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSigningUp
                      ? const SpinKitCircle(color: Colors.white, size: 24)
                      : const Text("Sign Up", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
