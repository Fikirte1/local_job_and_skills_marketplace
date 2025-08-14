import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/auth_service.dart';
import '../../utilities/region_city_data.dart';
import '../home/job_seeker_screens/job_seeker_dashboard.dart';

class JobSeekerSignupScreen extends StatefulWidget {
  @override
  _JobSeekerSignupScreenState createState() => _JobSeekerSignupScreenState();
}

class _JobSeekerSignupScreenState extends State<JobSeekerSignupScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _userTitleController = TextEditingController();

  String? _selectedSex;
  List<String> _cities = [];
  String? _selectedRegion;
  String? _selectedCity;

  bool _isSigningUp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNumberController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _userTitleController.dispose();
    super.dispose();
  }

  void _updateCities(String? region) {
    setState(() {
      _selectedRegion = region;
      _cities = region != null ? RegionCityData.regionCitiesMap[region] ?? [] : [];
      _selectedCity = null;
      _cityController.text = '';
    });
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords don't match")));
      return;
    }

    if (_selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select your gender")));
      return;
    }

    if (_selectedRegion == null || !RegionCityData.regions.contains(_selectedRegion)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a valid region")));
      return;
    }

    if (_cityController.text.isNotEmpty &&
        (_selectedCity == null || !_cities.contains(_selectedCity))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a valid city")));
      return;
    }

    setState(() => _isSigningUp = true);

    try {
      final user = await _authService.registerJobSeeker(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        sex: _selectedSex!,
        userTitle: _userTitleController.text.trim().isNotEmpty
            ? _userTitleController.text.trim()
            : null,
        region: _selectedRegion,
        city: _selectedCity,
      );

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => JobSeekerDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isSigningUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Job Seeker Registration"),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Create Your Account",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Fill in your basic information to get started", style: TextStyle(color: Colors.grey)),
                SizedBox(height: 24),

                _buildTextField("Full Name", _nameController, Icons.person,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter your full name";
                    }

                    if (val.trim().length < 2) {
                      return "Name is too short";
                    }

                    final nameRegex = RegExp(r"^[A-Za-z\s'-]+$");
                    if (!nameRegex.hasMatch(val.trim())) {
                      return "Name can only contain letters and spaces";
                    }

                    if (RegExp(r"^\d+$").hasMatch(val.trim())) {
                      return "Name cannot be numbers only";
                    }

                    return null;
                  },
                ),
                SizedBox(height: 16),

                _buildTextField("Email", _emailController, Icons.email,
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
                SizedBox(height: 16),

                _buildTextField("Password", _passwordController, Icons.lock,
                    obscureText: true,
                    validator: (val) =>
                    val == null || val.isEmpty || val.length < 6 ? "Password must be at least 6 characters" : null),
                SizedBox(height: 16),

                _buildTextField("Confirm Password", _confirmPasswordController, Icons.lock,
                    obscureText: true,
                    validator: (val) => val != _passwordController.text ? "Passwords don't match" : null),
                SizedBox(height: 16),

                _buildPhoneNumberField(),

                SizedBox(height: 16),

                _buildDropdown("Gender", _selectedSex, ['Male', 'Female'],
                    icon: Icons.person_outline,
                    onChanged: (val) => setState(() => _selectedSex = val)),
                SizedBox(height: 16),

                _buildDropdown("Professional Title", _userTitleController.text.isNotEmpty ? _userTitleController.text : null,
                    RegionCityData.professional_title,
                    icon: Icons.work,
                    onChanged: (val) => setState(() => _userTitleController.text = val ?? '')),
                SizedBox(height: 16),

                _buildDropdown("Region", _selectedRegion, RegionCityData.regions,
                    icon: Icons.location_on,
                    onChanged: (val) {
                      _updateCities(val);
                    }),
                SizedBox(height: 16),

                _buildDropdown("City", _selectedCity, _cities,
                    icon: Icons.location_city,
                    onChanged: _selectedRegion != null
                        ? (val) {
                      setState(() {
                        _selectedCity = val;
                        _cityController.text = val ?? '';
                      });
                    }
                        : null),
                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSigningUp ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSigningUp
                        ? SpinKitCircle(color: Colors.white, size: 24)
                        : Text("Sign Up", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          child: Text("+251", style: TextStyle(fontSize: 16 ,fontWeight:FontWeight.bold )),
        ),
        Expanded(
          child: TextFormField(
            controller: _contactNumberController,
            keyboardType: TextInputType.number,
            maxLength: 9,
            decoration: InputDecoration(
              counterText: '',
              hintText: "9XXXXXXXX",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter phone number';
              if (!RegExp(r'^[7-9]\d{8}$').hasMatch(value)) {
                return 'Enter valid 9-digit number starting with 7–9';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }


  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      {required IconData icon, void Function(String?)? onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(item),
      ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? "Please select your $label" : null,
    );
  }
}
