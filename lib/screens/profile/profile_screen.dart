import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smartpay_flutter/core/ui_constants.dart';
import '../../core/constants.dart';
import '../../data/models/profile_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileModel? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _profileService.getProfileData();
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile', style: UIConstants.pageTitleStyle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(_profileData),
                      _buildSection('Personal Details', [
                        _buildInfoRow('Full Name', _profileData?.empName ?? ''),
                        _buildInfoRow('Date of Birth', _profileData?.dob ?? ''),
                        _buildInfoRow('Gender', _profileData?.sex ?? ''),
                        _buildInfoRow('Blood Group', _profileData?.bloodGroup ?? ''),
                        _buildInfoRow('Nationality', _profileData?.nationality ?? ''),
                        _buildInfoRow('Religion', _profileData?.reliName ?? ''),
                        _buildInfoRow('Marital Status', _profileData?.mStatus ?? ''),
                      ]),
                      _buildSection('Employment Details', [
                        _buildInfoRow('Employee ID', _profileData?.empCode ?? ''),
                        _buildInfoRow('Designation', _profileData?.desName ?? ''),
                        _buildInfoRow('Department', _profileData?.deptName ?? ''),
                        _buildInfoRow('Location', _profileData?.locName ?? ''),
                        _buildInfoRow('Category', _profileData?.catName ?? ''),
                        _buildInfoRow('Date of Joining', _profileData?.doj ?? ''),
                        _buildInfoRow('HOD / Manager', _profileData?.hodName ?? ''),
                      ]),
                      _buildSection('Contact Information', [
                        _buildInfoRow('Official Email', _profileData?.officeEmail ?? ''),
                        _buildInfoRow('Personal Email', _profileData?.emailId ?? ''),
                        _buildInfoRow('Mobile', _profileData?.mobileNo ?? ''),
                        _buildInfoRow('Phone', _profileData?.phoneNo ?? ''),
                        _buildInfoRow('Emergency Contact', _profileData?.eContactName ?? ''),
                        _buildInfoRow('Emergency Number', _profileData?.eContactNumber ?? ''),
                      ]),
                      _buildSection('Address Details', [
                        _buildInfoRow('Address', _profileData?.address ?? ''),
                        _buildInfoRow('City', _profileData?.city ?? ''),
                        _buildInfoRow('State', _profileData?.stateName ?? ''),
                        _buildInfoRow('Country', _profileData?.countryName ?? ''),
                        _buildInfoRow('Pin Code', _profileData?.pinCode ?? ''),
                      ]),
                      _buildSection('Statutory Details', [
                        _buildInfoRow('PAN No', _profileData?.panNo ?? '', base64Data: _profileData?.panBase64),
                        _buildInfoRow('Aadhaar No', _profileData?.adharNo ?? '', base64Data: _profileData?.adharBase64),
                        _buildInfoRow('Passport No', _profileData?.passportNo ?? '', base64Data: _profileData?.passportBase64),
                        _buildInfoRow('DL No', _profileData?.dlNo ?? '', base64Data: _profileData?.dlBase64),
                        _buildInfoRow('UAN No', _profileData?.uanNo ?? ''),
                        _buildInfoRow('PF No', _profileData?.pfNo ?? ''),
                        _buildInfoRow('ESI No', _profileData?.esiNo ?? ''),
                      ]),
                      _buildSection('Bank Details', [
                        _buildInfoRow('Bank Name', _profileData?.bankName ?? ''),
                        _buildInfoRow('Account No', _profileData?.accountNo ?? ''),
                        _buildInfoRow('IFSC Code', _profileData?.ifsCode ?? ''),
                        _buildInfoRow('Insurance No', _profileData?.insuranceNo ?? '', base64Data: _profileData?.insuranceBase64),
                      ]),
                      if (_profileData?.eduDetails.isNotEmpty ?? false)
                        _buildSection('Educational Qualifications', 
                          _profileData!.eduDetails.map((edu) => _buildInfoRow(edu.degree ?? 'Education', '${edu.institution ?? ""}${edu.passDate != null ? " (${edu.passDate})" : ""}')).toList()
                        ),
                      if (_profileData?.expDetails.isNotEmpty ?? false)
                        _buildSection('Previous Experience', 
                          _profileData!.expDetails.map((exp) => _buildInfoRow(exp.companyName ?? 'Company', '${exp.role ?? ""}${exp.expFrom != null ? " (${exp.expFrom} - ${exp.expTo})" : ""}')).toList()
                        ),
                      if (_profileData?.insDetails.isNotEmpty ?? false)
                        _buildSection('Insurance Details', 
                          _profileData!.insDetails.map((ins) => _buildInfoRow(ins.insuranceName ?? 'Insurance', '${ins.insCompanyName ?? ""}${ins.insNo != null ? " (${ins.insNo})" : ""}')).toList()
                        ),
                      if (_profileData?.familyDetails.isNotEmpty ?? false)
                        _buildSection('Family Details', 
                          _profileData!.familyDetails.map((f) => _buildInfoRow(f.mName ?? 'Member', '${f.mRelation ?? ""}${f.mobileNo != null ? " (${f.mobileNo})" : ""}')).toList()
                        ),
                      if (_profileData?.langDetails.isNotEmpty ?? false)
                        _buildSection('Language Skills', 
                          _profileData!.langDetails.map((l) => _buildInfoRow(l.language ?? 'Language', '${l.isSpeak ? "Speak " : ""}${l.isRead ? "Read " : ""}${l.isWrite ? "Write" : ""}')).toList()
                        ),
                      const SizedBox(height: 20),
                      _buildLogoutButton(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(ProfileModel? data) {
    String? photoBase64 = data?.photoBase64;
    ImageProvider profileImage;

    if (photoBase64 != null && photoBase64.isNotEmpty) {
      profileImage = MemoryImage(base64Decode(photoBase64));
    } else {
      profileImage = const AssetImage('assets/images/user_placeholder.png');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: photoBase64 != null && photoBase64.isNotEmpty 
                  ? profileImage 
                  : null,
              child: photoBase64 == null || photoBase64.isEmpty
                  ? const Icon(Icons.person, size: 70, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            data?.empName ?? 'Employee',
            style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizePageTitle, fontWeight: FontWeight.bold),
          ),
          Text(
            data?.empCode ?? '',
            style: TextStyle(color: Colors.white70, fontSize: UIConstants.fontSizeSectionHeader),
          ),
          if (data?.desName != null)
            Text(
              data!.desName!,
              style: TextStyle(color: Colors.white60, fontSize: UIConstants.fontSizeBody),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    // Filter out rows with empty values
    final validChildren = children.where((child) {
      if (child is _InfoRow) {
        return child.value.isNotEmpty && child.value != 'NONE' && child.value != '-';
      }
      return true;
    }).toList();

    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: UIConstants.fontSizeSectionHeader, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const Divider(height: 25),
          ...validChildren,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? base64Data, String? title}) {
    return _InfoRow(
      label: label, 
      value: value, 
      onView: base64Data != null && base64Data.isNotEmpty 
          ? () => _showDocument(title ?? label, base64Data) 
          : null,
    );
  }

  void _showDocument(String title, String base64Data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: TextStyle(fontSize: UIConstants.fontSizeSectionHeader)),
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.memory(
                base64Decode(base64Data),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text('Could not load document image'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            AuthService().logout();
            Navigator.pushReplacementNamed(context, '/');
          },
          icon: const Icon(Icons.logout, color: AppColors.error),
          label: const Text('Logout', style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onView;

  const _InfoRow({required this.label, required this.value, this.onView});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: AppColors.textGray, fontSize: UIConstants.fontSizeBody)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value, 
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: UIConstants.fontSizeBody, color: AppColors.textDark),
                  textAlign: TextAlign.end,
                ),
                if (onView != null)
                  TextButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text('View Document', style: TextStyle(fontSize: UIConstants.fontSizeSmall)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
