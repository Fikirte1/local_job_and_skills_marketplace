import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employer_model/employer_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployersProfileForAdminsScreen extends StatelessWidget {
  final Employer employer;

  const EmployersProfileForAdminsScreen({super.key, required this.employer});

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showDocumentBottomSheet(BuildContext context, String documentUrl) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${employer.companyName} Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildBasicInfoSection(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
            const SizedBox(height: 24),
            _buildContactSection(context),
            const SizedBox(height: 24),
            _buildDocumentsSection(context),
            const SizedBox(height: 24),
            _buildVerificationSection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage:
          employer.logoUrl != null ? NetworkImage(employer.logoUrl!) : null,
          child: employer.logoUrl == null
              ? const Icon(Icons.business, size: 60, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Text(
              employer.companyName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (employer.industry != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  employer.industry!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              ),
            if (employer.region != null || employer.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      [employer.city, employer.region].where((e) => e != null).join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(employer.verificationStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(employer.verificationStatus)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(employer.verificationStatus),
                    color: _getStatusColor(employer.verificationStatus),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    employer.verificationStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(employer.verificationStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _buildInfoTile(context, 'Company Name', employer.companyName, Icons.business),
            if (employer.industry != null)
              _buildInfoTile(context, 'Industry', employer.industry!, Icons.category),
            if (employer.website != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link, color: Colors.grey),
                title: Text('Website',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                subtitle: InkWell(
                  onTap: () => _launchURL(employer.website!),
                  child: Text(
                    employer.website!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('About Company',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          Text(employer.aboutCompany, style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          _buildInfoTile(context, 'Email', employer.email, Icons.email),
          _buildInfoTile(context, 'Contact Number', employer.contactNumber, Icons.phone),
          if (employer.region != null || employer.city != null)
            _buildInfoTile(
              context,
              'Location',
              [employer.city, employer.region].where((e) => e != null).join(', '),
              Icons.location_on,
            ),
        ]),
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Company Documents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          if (employer.identityDocumentUrl == null)
            Text('No verification documents uploaded',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey))
          else
            _buildDocumentTile(context, 'Verification Document',
                employer.identityDocumentUrl!, employer.documentType ?? 'Document'),
        ]),
      ),
    );
  }

  Widget _buildVerificationSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Verification Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          Row(children: [
            Icon(_getStatusIcon(employer.verificationStatus),
                color: _getStatusColor(employer.verificationStatus)),
            const SizedBox(width: 12),
            Text(employer.verificationStatus,
                style: TextStyle(
                  color: _getStatusColor(employer.verificationStatus),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ]),
          const SizedBox(height: 12),
          if (employer.verificationSubmittedAt != null)
            _buildInfoTile(context, 'Submitted Date',
                DateFormat('MMM d, yyyy').format(employer.verificationSubmittedAt!), Icons.calendar_today),
          if (employer.verifiedAt != null)
            _buildInfoTile(context, 'Verified Date',
                DateFormat('MMM d, yyyy').format(employer.verifiedAt!), Icons.verified),
          if (employer.verifiedByName != null)
            _buildInfoTile(context, 'Verified By', employer.verifiedByName!, Icons.person),
          if (employer.verificationMessage != null) ...[
            const SizedBox(height: 12),
            Text('Admin Message:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(employer.verificationMessage!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildDocumentTile(
      BuildContext context, String title, String url, String type) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(type),
      trailing: IconButton(
        icon: const Icon(Icons.visibility),
        tooltip: 'View',
        onPressed: () => _showDocumentBottomSheet(context, url),
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.verified;
      case 'Rejected':
        return Icons.warning;
      case 'Pending Review':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }
}
