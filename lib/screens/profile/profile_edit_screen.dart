import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../data/models/profile_model.dart';
import '../../data/services/profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  String? _error;
  
  ProfileModel? _profileData;
  Map<String, dynamic>? _lookupData;

  // Lists for dynamic sections
  List<EducationDetail> _eduDetails = [];
  List<ExperienceDetail> _expDetails = [];
  List<InsuranceDetail> _insDetails = [];
  List<LanguageDetail> _langDetails = [];
  List<FamilyDetail> _familyDetails = [];
  List<PFNomineeDetail> _pfNominees = [];
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _mNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  
  final TextEditingController _comAddressController = TextEditingController();
  final TextEditingController _comCityController = TextEditingController();
  final TextEditingController _comPinCodeController = TextEditingController();

  final TextEditingController _panNoController = TextEditingController();
  final TextEditingController _adharNoController = TextEditingController();
  final TextEditingController _passportNoController = TextEditingController();
  final TextEditingController _dlNoController = TextEditingController();
  final TextEditingController _insuranceNoController = TextEditingController();
  final TextEditingController _eContactNameController = TextEditingController();
  final TextEditingController _eContactNumberController = TextEditingController();
  final TextEditingController _eContactRelationController = TextEditingController();
  final TextEditingController _dlExpDateController = TextEditingController();
  final TextEditingController _passportExpDateController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _spouseNameController = TextEditingController();
  final TextEditingController _cugNoController = TextEditingController();
  final TextEditingController _officeEmailController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _ifsCodeController = TextEditingController();
  final TextEditingController _uanNoController = TextEditingController();
  final TextEditingController _pfNoController = TextEditingController();
  final TextEditingController _esiNoController = TextEditingController();
  final TextEditingController _medicalIssuesController = TextEditingController();
  final TextEditingController _incDateController = TextEditingController();
  
  // Off-Boarding
  final TextEditingController _resignDateController = TextEditingController();
  final TextEditingController _resignReasonHeadController = TextEditingController();
  final TextEditingController _resignReasonController = TextEditingController();
  bool _isResign = false;

  // ESS Login
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _empPortal = false;

  String? _selectedSex;
  String? _selectedMStatus;
  String? _selectedBloodGroup;
  String? _selectedState;
  String? _selectedCountry;
  String? _selectedComState;
  String? _selectedComCountry;
  String? _selectedReligion;
  String? _selectedNationality;
  bool _sameAddress = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _profileService.getProfileData(action: 'Modify'),
        _profileService.getLookupData(),
      ]);

      setState(() {
        _profileData = results[0] as ProfileModel;
        _lookupData = results[1] as Map<String, dynamic>;
        
        // Initialize lists
        _eduDetails = List.from(_profileData!.eduDetails);
        _expDetails = List.from(_profileData!.expDetails);
        _insDetails = List.from(_profileData!.insDetails);
        _langDetails = List.from(_profileData!.langDetails);
        _familyDetails = List.from(_profileData!.familyDetails);
        _pfNominees = List.from(_profileData!.pfNominees);
        
        // Initialize controllers
        _fNameController.text = _profileData?.empFName ?? '';
        _prefixController.text = _profileData?.prefix ?? '';
        _mNameController.text = _profileData?.empMiddleName ?? '';
        _lNameController.text = _profileData?.empLName ?? '';
        _fatherNameController.text = _profileData?.fName ?? '';
        _phoneController.text = _profileData?.phoneNo ?? '';
        _emailController.text = _profileData?.emailId ?? '';
        
        _addressController.text = _profileData?.address ?? '';
        _cityController.text = _profileData?.city ?? '';
        _pinCodeController.text = _profileData?.pinCode ?? '';
        
        _comAddressController.text = _profileData?.comAddress ?? '';
        _comCityController.text = _profileData?.comCity ?? '';
        _comPinCodeController.text = _profileData?.comPinCode ?? '';

        _panNoController.text = _profileData?.panNo ?? '';
        _adharNoController.text = _profileData?.adharNo ?? '';
        _passportNoController.text = _profileData?.passportNo ?? '';
        _dlNoController.text = _profileData?.dlNo ?? '';
        _insuranceNoController.text = _profileData?.insuranceNo ?? '';
        _eContactNameController.text = _profileData?.eContactName ?? '';
        _eContactNumberController.text = _profileData?.eContactNumber ?? '';
        _eContactRelationController.text = _profileData?.eContactRelation ?? '';
        _dlExpDateController.text = _profileData?.dlExpDate ?? '';
        _passportExpDateController.text = _profileData?.passportExpDate ?? '';
        _dobController.text = _profileData?.dob ?? '';
        _nationalityController.text = _profileData?.nationality ?? '';
        _religionController.text = _profileData?.reliName ?? '';
        _spouseNameController.text = _profileData?.hName ?? '';
        _cugNoController.text = _profileData?.cugNo ?? '';
        _officeEmailController.text = _profileData?.officeEmail ?? '';
        _bankNameController.text = _profileData?.bankName ?? '';
        _accountNoController.text = _profileData?.accountNo ?? '';
        _ifsCodeController.text = _profileData?.ifsCode ?? '';
        _uanNoController.text = _profileData?.uanNo ?? '';
        _pfNoController.text = _profileData?.pfNo ?? '';
        _esiNoController.text = _profileData?.esiNo ?? '';
        _medicalIssuesController.text = _profileData?.medicalIssues ?? '';
        _incDateController.text = _profileData?.incDate ?? '';

        _resignDateController.text = _profileData?.resignDate ?? '';
        _resignReasonHeadController.text = _profileData?.resignReasonHead ?? '';
        _resignReasonController.text = _profileData?.resignReason ?? '';
        _isResign = _profileData?.isResign ?? false;

        _userNameController.text = _profileData?.userName ?? '';
        _passwordController.text = _profileData?.password ?? '';
        _empPortal = _profileData?.empPortal ?? false;

        _selectedSex = _profileData?.sex;
        _selectedMStatus = _profileData?.mStatus;
        _selectedBloodGroup = _profileData?.bloodGroup;
        _selectedState = _profileData?.stateName;
        _selectedCountry = _profileData?.countryName;
        _selectedComState = _profileData?.comStateName;
        _selectedComCountry = _profileData?.comCountryName;
        _selectedReligion = _profileData?.reliName;
        _selectedNationality = _profileData?.nationality;
        _sameAddress = _profileData?.sameAddress ?? false;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        String? idNumber;
        String? insuranceNo;

        if (type == 'Pan') idNumber = _panNoController.text;
        if (type == 'Adhar') idNumber = _adharNoController.text;
        if (type == 'DL') idNumber = _dlNoController.text;
        if (type == 'Passport') idNumber = _passportNoController.text;
        if (type == 'Card') insuranceNo = _insuranceNoController.text;

        if ((type != 'Photo' && type != 'Card') && (idNumber == null || idNumber.isEmpty)) {
          throw Exception('Please enter $type number first');
        }
        
        if (type == 'Card' && (insuranceNo == null || insuranceNo.isEmpty)) {
          throw Exception('Please enter Insurance number first');
        }

        await _profileService.uploadProfileDocument(
          type: type,
          file: File(result.files.single.path!),
          idNumber: idNumber,
          insuranceNo: insuranceNo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$type uploaded successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = ProfileModel(
        empFName: _fNameController.text,
        prefix: _prefixController.text,
        empMiddleName: _mNameController.text,
        empLName: _lNameController.text,
        fName: _fatherNameController.text,
        hName: _spouseNameController.text,
        sex: _selectedSex,
        mStatus: _selectedMStatus,
        bloodGroup: _selectedBloodGroup,
        dob: _dobController.text,
        address: _addressController.text,
        city: _cityController.text,
        pinCode: _pinCodeController.text,
        stateName: _selectedState,
        countryName: _selectedCountry,
        sameAddress: _sameAddress,
        comAddress: _sameAddress ? _addressController.text : _comAddressController.text,
        comCity: _sameAddress ? _cityController.text : _comCityController.text,
        comPinCode: _sameAddress ? _pinCodeController.text : _comPinCodeController.text,
        comStateName: _sameAddress ? _selectedState : _selectedComState,
        comCountryName: _sameAddress ? _selectedCountry : _selectedComCountry,
        phoneNo: _phoneController.text,
        mobileNo: _phoneController.text,
        emailId: _emailController.text,
        officeEmail: _officeEmailController.text,
        cugNo: _cugNoController.text,
        reliName: _religionController.text,
        nationality: _nationalityController.text,
        actions: "Modify",
        empCode: _profileData?.empCode,
        editId: _profileData?.editId ?? "0",
        dtEarn: _profileData?.dtEarn ?? [],
        dtDed: _profileData?.dtDed ?? [],
        ctc: _profileData?.ctc ?? "0",
        incDate: _incDateController.text,
        medicalIssues: _medicalIssuesController.text,
        isResign: _isResign,
        resignDate: _resignDateController.text,
        resignReasonHead: _resignReasonHeadController.text,
        resignReason: _resignReasonController.text,
        empPortal: _empPortal,
        userName: _userNameController.text,
        password: _passwordController.text,
        bankName: _bankNameController.text,
        accountNo: _accountNoController.text,
        ifsCode: _ifsCodeController.text,
        uanNo: _uanNoController.text,
        pfNo: _pfNoController.text,
        esiNo: _esiNoController.text,
        familyDetails: _familyDetails,
        eduDetails: _eduDetails,
        expDetails: _expDetails,
        pfNominees: _pfNominees,
        dtPFDet: [], // Set to empty as we use pfNominees
        insDetails: _insDetails,
        langDetails: _langDetails,
        panNo: _panNoController.text,
        adharNo: _adharNoController.text,
        passportNo: _passportNoController.text,
        dlNo: _dlNoController.text,
        insuranceNo: _insuranceNoController.text,
        eContactName: _eContactNameController.text,
        eContactNumber: _eContactNumberController.text,
        eContactRelation: _eContactRelationController.text,
        dlExpDate: _dlExpDateController.text,
        passportExpDate: _passportExpDateController.text,
        hodName: _profileData?.hodName,
        extraData: _profileData?.extraData ?? {},
      );

      await _profileService.submitProfile(updatedProfile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<String> _getLookupList(String key, String displayField) {
    if (_profileData == null || _profileData![key] == null) {
      if (_lookupData != null && _lookupData![key] != null) {
        return (_lookupData![key] as List).map((e) => e[displayField].toString()).toList();
      }
      return [];
    }
    return (_profileData![key] as List).map((e) => e[displayField].toString()).toList();
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _prefixController.dispose();
    _mNameController.dispose();
    _lNameController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _comAddressController.dispose();
    _comCityController.dispose();
    _comPinCodeController.dispose();
    _panNoController.dispose();
    _adharNoController.dispose();
    _passportNoController.dispose();
    _dlNoController.dispose();
    _insuranceNoController.dispose();
    _eContactNameController.dispose();
    _eContactNumberController.dispose();
    _eContactRelationController.dispose();
    _dlExpDateController.dispose();
    _passportExpDateController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _spouseNameController.dispose();
    _cugNoController.dispose();
    _officeEmailController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifsCodeController.dispose();
    _uanNoController.dispose();
    _pfNoController.dispose();
    _esiNoController.dispose();
    _medicalIssuesController.dispose();
    _incDateController.dispose();
    _resignDateController.dispose();
    _resignReasonHeadController.dispose();
    _resignReasonController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sexList = _getLookupList('dtSex', 'Sex');
    final mStatusList = _getLookupList('dtMStatus', 'MStatus');
    final bloodGroupList = _getLookupList('dtBloodGroup', 'BloodGroup');
    final stateList = _getLookupList('dtState', 'StateName');
    final countryList = _getLookupList('dtCountry', 'CountryName');
    final religionList = _getLookupList('dtReli', 'ReliName');
    final nationalityList = _getLookupList('dtNat', 'NatName');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modify Profile', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _handleSave,
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
                      ElevatedButton(onPressed: _loadInitialData, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Basic Information'),
                        _buildTextField('Prefix', _prefixController),
                        _buildTextField('First Name', _fNameController, required: true),
                        _buildTextField('Middle Name', _mNameController),
                        _buildTextField('Last Name', _lNameController, required: true),
                        _buildTextField('Father\'s Name', _fatherNameController),
                        _buildTextField('Spouse Name', _spouseNameController),
                        _buildDateField('Date of Birth', _dobController),
                        
                        Row(
                          children: [
                            Expanded(child: _buildDropdown('Gender', _selectedSex, sexList, (val) => setState(() => _selectedSex = val))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDropdown('Marital Status', _selectedMStatus, mStatusList, (val) => setState(() => _selectedMStatus = val))),
                          ],
                        ),
                        
                        _buildDropdown('Blood Group', _selectedBloodGroup, bloodGroupList, (val) => setState(() => _selectedBloodGroup = val)),
                        
                        Row(
                          children: [
                            Expanded(
                              child: nationalityList.isNotEmpty 
                                ? _buildDropdown('Nationality', _selectedNationality, nationalityList, (val) {
                                    setState(() {
                                      _selectedNationality = val;
                                      _nationalityController.text = val ?? '';
                                    });
                                  })
                                : _buildTextField('Nationality', _nationalityController),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: religionList.isNotEmpty
                                ? _buildDropdown('Religion', _selectedReligion, religionList, (val) {
                                    setState(() {
                                      _selectedReligion = val;
                                      _religionController.text = val ?? '';
                                    });
                                  })
                                : _buildTextField('Religion', _religionController),
                            ),
                          ],
                        ),

                        _buildSectionHeader('Contact Details'),
                        _buildTextField('Mobile No', _phoneController, required: true, keyboardType: TextInputType.phone),
                        _buildTextField('CUG No', _cugNoController, keyboardType: TextInputType.phone),
                        _buildTextField('Personal Email', _emailController, required: true, keyboardType: TextInputType.emailAddress),
                        _buildTextField('Official Email', _officeEmailController, keyboardType: TextInputType.emailAddress),

                        _buildSectionHeader('Emergency Contact'),
                        _buildTextField('Contact Name', _eContactNameController),
                        _buildTextField('Contact Number', _eContactNumberController, keyboardType: TextInputType.phone),
                        _buildTextField('Relation', _eContactRelationController),

                        _buildSectionHeader('Permanent Address'),
                        _buildTextField('Address', _addressController, required: true),
                        _buildTextField('City', _cityController, required: true),
                        
                        Row(
                          children: [
                            Expanded(child: _buildDropdown('State', _selectedState, stateList, (val) => setState(() => _selectedState = val))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDropdown('Country', _selectedCountry, countryList, (val) => setState(() => _selectedCountry = val))),
                          ],
                        ),

                        _buildTextField('Pin Code', _pinCodeController, required: true, keyboardType: TextInputType.number),

                        Row(
                          children: [
                            Checkbox(
                              value: _sameAddress,
                              onChanged: (val) {
                                setState(() {
                                  _sameAddress = val ?? false;
                                  if (_sameAddress) {
                                    _comAddressController.text = _addressController.text;
                                    _comCityController.text = _cityController.text;
                                    _comPinCodeController.text = _pinCodeController.text;
                                    _selectedComState = _selectedState;
                                    _selectedComCountry = _selectedCountry;
                                  }
                                });
                              },
                            ),
                            const Text('Same as Permanent Address'),
                          ],
                        ),

                        if (!_sameAddress) ...[
                          _buildSectionHeader('Communication Address'),
                          _buildTextField('Address', _comAddressController),
                          _buildTextField('City', _comCityController),
                          Row(
                            children: [
                              Expanded(child: _buildDropdown('State', _selectedComState, stateList, (val) => setState(() => _selectedComState = val))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDropdown('Country', _selectedComCountry, countryList, (val) => setState(() => _selectedComCountry = val))),
                            ],
                          ),
                          _buildTextField('Pin Code', _comPinCodeController, keyboardType: TextInputType.number),
                        ],

                        _buildSectionHeader('Documents & ID Proofs'),
                        
                        _buildUploadField('Profile Photo', null, 'Photo'),
                        _buildUploadField('PAN Number', _panNoController, 'Pan'),
                        _buildUploadField('Aadhaar Number', _adharNoController, 'Adhar'),
                        _buildUploadField('Passport Number', _passportNoController, 'Passport'),
                        _buildDateField('Passport Expiry Date', _passportExpDateController),
                        _buildUploadField('Driving License', _dlNoController, 'DL'),
                        _buildDateField('DL Expiry Date', _dlExpDateController),
                        _buildUploadField('Insurance Number', _insuranceNoController, 'Card'),
                        
                        _buildSectionHeader('Bank Details'),
                        _buildTextField('Bank Name', _bankNameController),
                        _buildTextField('Account No', _accountNoController),
                        _buildTextField('IFSC Code', _ifsCodeController),

                        _buildSectionHeader('Statutory Details'),
                        _buildTextField('PF No', _pfNoController),
                        _buildTextField('UAN No', _uanNoController),
                        _buildTextField('ESI No', _esiNoController),

                        _buildSectionHeader('Other Information'),
                        _buildTextField('Medical Issues', _medicalIssuesController),
                        _buildDateField('Increment Date', _incDateController),
                        
                        _buildSectionHeader('Off-Boarding'),
                        SwitchListTile(
                          title: const Text('Is Resigned?'),
                          value: _isResign,
                          onChanged: (val) => setState(() => _isResign = val),
                          activeThumbColor: AppColors.primary,
                        ),
                        if (_isResign) ...[
                          _buildDateField('Resignation Date', _resignDateController),
                          _buildTextField('Resignation Reason Head', _resignReasonHeadController),
                          _buildTextField('Resignation Reason', _resignReasonController, maxLines: 3),
                        ],

                        _buildSectionHeader('ESS Login'),
                        SwitchListTile(
                          title: const Text('Enable ESS Portal?'),
                          value: _empPortal,
                          onChanged: (val) => setState(() => _empPortal = val),
                          activeThumbColor: AppColors.primary,
                        ),
                        if (_empPortal) ...[
                          _buildTextField('User Name', _userNameController),
                          _buildTextField('Password', _passwordController, obscureText: true),
                        ],

                        _buildSectionHeader('Educational Qualifications'),
                        ..._buildEduList(),
                        _buildAddButton('Add Education', _addEducation),

                        _buildSectionHeader('Previous Experience'),
                        ..._buildExpList(),
                        _buildAddButton('Add Experience', _addExperience),

                        _buildSectionHeader('Family Details'),
                        ..._buildFamilyList(),
                        _buildAddButton('Add Family Member', _addFamilyMember),

                        _buildSectionHeader('Insurance Details'),
                        ..._buildInsList(),
                        _buildAddButton('Add Insurance', _addInsurance),

                        _buildSectionHeader('PF Nominee Details'),
                        ..._buildPFNomineeList(),
                        _buildAddButton('Add PF Nominee', _addPFNominee),

                        _buildSectionHeader('Language Skills'),
                        ..._buildLangList(),
                        _buildAddButton('Add Language', _addLanguage),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Submit Modification Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  List<Widget> _buildEduList() {
    return _eduDetails.asMap().entries.map((entry) {
      int index = entry.key;
      EducationDetail edu = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(edu.degree ?? 'Education'),
          subtitle: Text('${edu.institution ?? ""}\n${edu.passDate ?? ""}'),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editEducation(index)),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removeEducation(index)),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addEducation() => _showEduDialog();
  void _editEducation(int index) => _showEduDialog(index: index);
  void _removeEducation(int index) => setState(() => _eduDetails.removeAt(index));

  void _showEduDialog({int? index}) {
    final edu = index != null ? _eduDetails[index] : null;
    final degreeTypeList = _getLookupList('dtDegreeType', 'DegreeType');
    
    String? selectedType = edu?.degreeType;
    final degreeController = TextEditingController(text: edu?.degree);
    final instController = TextEditingController(text: edu?.institution);
    final subjectController = TextEditingController(text: edu?.subject);
    final passYearController = TextEditingController(text: edu?.passYear);
    final dateController = TextEditingController(text: edu?.passDate);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Add Education' : 'Edit Education'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdown('Degree Type', selectedType, degreeTypeList, (val) => setDialogState(() => selectedType = val)),
                _buildTextField('Degree', degreeController),
                _buildTextField('Institution', instController),
                _buildTextField('Subject', subjectController),
                _buildTextField('Passing Year', passYearController),
                _buildDateField('Passing Date', dateController, setState: setDialogState),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final newEdu = EducationDetail(
                  id: edu?.id ?? "0",
                  degreeType: selectedType,
                  degree: degreeController.text,
                  institution: instController.text,
                  subject: subjectController.text,
                  passYear: passYearController.text,
                  passDate: dateController.text,
                  filePath: edu?.filePath,
                );
                setState(() {
                  if (index == null) {
                    _eduDetails.add(newEdu);
                  } else {
                    _eduDetails[index] = newEdu;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExpList() {
    return _expDetails.asMap().entries.map((entry) {
      int index = entry.key;
      ExperienceDetail exp = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(exp.companyName ?? 'Experience'),
          subtitle: Text('${exp.role ?? ""}\n${exp.expFrom ?? ""} - ${exp.expTo ?? ""}'),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editExperience(index)),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removeExperience(index)),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addExperience() => _showExpDialog();
  void _editExperience(int index) => _showExpDialog(index: index);
  void _removeExperience(int index) => setState(() => _expDetails.removeAt(index));

  void _showExpDialog({int? index}) {
    final exp = index != null ? _expDetails[index] : null;
    final companyController = TextEditingController(text: exp?.companyName);
    final roleController = TextEditingController(text: exp?.role);
    final durationController = TextEditingController(text: exp?.duration);
    final fromController = TextEditingController(text: exp?.expFrom);
    final toController = TextEditingController(text: exp?.expTo);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Add Experience' : 'Edit Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Company Name', companyController),
                _buildTextField('Role', roleController),
                _buildTextField('Duration', durationController),
                _buildDateField('From Date', fromController, setState: setDialogState),
                _buildDateField('To Date', toController, setState: setDialogState),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final newExp = ExperienceDetail(
                  id: exp?.id ?? "0",
                  companyName: companyController.text,
                  role: roleController.text,
                  duration: durationController.text,
                  expFrom: fromController.text,
                  expTo: toController.text,
                  filePath: exp?.filePath,
                  filePath1: exp?.filePath1,
                );
                setState(() {
                  if (index == null) {
                    _expDetails.add(newExp);
                  } else {
                    _expDetails[index] = newExp;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFamilyList() {
    return _familyDetails.asMap().entries.map((entry) {
      int index = entry.key;
      FamilyDetail member = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(member.mName ?? 'Member'),
          subtitle: Text('${member.mRelation ?? ""}\n${member.mobileNo ?? ""}'),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editFamilyMember(index)),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removeFamilyMember(index)),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addFamilyMember() => _showFamilyDialog();
  void _editFamilyMember(int index) => _showFamilyDialog(index: index);
  void _removeFamilyMember(int index) => setState(() => _familyDetails.removeAt(index));

  void _showFamilyDialog({int? index}) {
    final member = index != null ? _familyDetails[index] : null;
    final relationList = _getLookupList('dtRelation', 'Relation');
    final bloodGroupList = _getLookupList('dtBloodGroup', 'BloodGroup');
    
    final nameController = TextEditingController(text: member?.mName);
    String? selectedRelation = member?.mRelation;
    String? selectedBloodGroup = member?.bloodGroup;
    final phoneController = TextEditingController(text: member?.mobileNo);
    final dobController = TextEditingController(text: member?.dob);
    final adharController = TextEditingController(text: member?.adharNo);
    final eduController = TextEditingController(text: member?.eduDetail);
    final occController = TextEditingController(text: member?.occDetail);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Add Family Member' : 'Edit Family Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Member Name', nameController),
                _buildDropdown('Relation', selectedRelation, relationList, (val) => setDialogState(() => selectedRelation = val)),
                _buildDropdown('Blood Group', selectedBloodGroup, bloodGroupList, (val) => setDialogState(() => selectedBloodGroup = val)),
                _buildTextField('Mobile No', phoneController),
                _buildDateField('Date of Birth', dobController, setState: setDialogState),
                _buildTextField('Aadhaar No', adharController),
                _buildTextField('Education', eduController),
                _buildTextField('Occupation', occController),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final newMember = FamilyDetail(
                  id: member?.id ?? "0",
                  mName: nameController.text,
                  mRelation: selectedRelation,
                  bloodGroup: selectedBloodGroup,
                  mobileNo: phoneController.text,
                  dob: dobController.text,
                  adharNo: adharController.text,
                  adharPath: member?.adharPath,
                  base64: member?.base64,
                  eduDetail: eduController.text,
                  occDetail: occController.text,
                );
                setState(() {
                  if (index == null) {
                    _familyDetails.add(newMember);
                  } else {
                    _familyDetails[index] = newMember;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInsList() {
    return _insDetails.asMap().entries.map((entry) {
      int index = entry.key;
      InsuranceDetail ins = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(ins.insuranceName ?? 'Insurance'),
          subtitle: Text('${ins.insCompanyName ?? ""}\n${ins.insNo ?? ""}'),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editInsurance(index)),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removeInsurance(index)),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addInsurance() => _showInsDialog();
  void _editInsurance(int index) => _showInsDialog(index: index);
  void _removeInsurance(int index) => setState(() => _insDetails.removeAt(index));

  void _showInsDialog({int? index}) {
    final ins = index != null ? _insDetails[index] : null;
    final insTypeList = _getLookupList('dtInsType', 'InsTypeName');
    
    String? selectedType = ins?.insTypeName;
    final nameController = TextEditingController(text: ins?.insuranceName);
    final companyController = TextEditingController(text: ins?.insCompanyName);
    final noController = TextEditingController(text: ins?.insNo);
    final forController = TextEditingController(text: ins?.insFor);
    final amountController = TextEditingController(text: ins?.insAmount);
    final startController = TextEditingController(text: ins?.startDate);
    final endController = TextEditingController(text: ins?.endDate);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Add Insurance' : 'Edit Insurance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdown('Insurance Type', selectedType, insTypeList, (val) => setDialogState(() => selectedType = val)),
                _buildTextField('Policy Name', nameController),
                _buildTextField('Company Name', companyController),
                _buildTextField('Policy No', noController),
                _buildTextField('Insurance For', forController),
                _buildTextField('Sum Assured', amountController),
                _buildDateField('Start Date', startController, setState: setDialogState),
                _buildDateField('End Date', endController, setState: setDialogState),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final newIns = InsuranceDetail(
                  id: ins?.id ?? "0",
                  insTypeName: selectedType,
                  insuranceName: nameController.text,
                  insCompanyName: companyController.text,
                  insNo: noController.text,
                  insFor: forController.text,
                  insAmount: amountController.text,
                  startDate: startController.text,
                  endDate: endController.text,
                  filePath: ins?.filePath,
                );
                setState(() {
                  if (index == null) {
                    _insDetails.add(newIns);
                  } else {
                    _insDetails[index] = newIns;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPFNomineeList() {
    return _pfNominees.asMap().entries.map((entry) {
      int index = entry.key;
      PFNomineeDetail nominee = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(nominee.memberName ?? 'Nominee'),
          subtitle: Text('Share: ${nominee.shareP ?? "0"}%'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editPFNominee(index)),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removePFNominee(index)),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addPFNominee() => _showPFNomineeDialog();
  void _editPFNominee(int index) => _showPFNomineeDialog(index: index);
  void _removePFNominee(int index) => setState(() => _pfNominees.removeAt(index));

  void _showPFNomineeDialog({int? index}) {
    final nominee = index != null ? _pfNominees[index] : null;
    final nameController = TextEditingController(text: nominee?.memberName);
    final shareController = TextEditingController(text: nominee?.shareP);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add PF Nominee' : 'Edit PF Nominee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Nominee Name', nameController),
            _buildTextField('Share %', shareController, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final shareVal = double.tryParse(shareController.text) ?? 0;
              double totalShare = 0;
              for (int i = 0; i < _pfNominees.length; i++) {
                if (i != index) {
                  totalShare += double.tryParse(_pfNominees[i].shareP ?? '0') ?? 0;
                }
              }
              
              if (totalShare + shareVal > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Total share percentage cannot exceed 100%')),
                );
                return;
              }

              final newNominee = PFNomineeDetail(
                id: nominee?.id ?? "0",
                memberName: nameController.text,
                shareP: shareController.text,
              );
              setState(() {
                if (index == null) {
                  _pfNominees.add(newNominee);
                } else {
                  _pfNominees[index] = newNominee;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLangList() {
    return _langDetails.asMap().entries.map((entry) {
      int index = entry.key;
      LanguageDetail lang = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(lang.language ?? 'Language'),
          subtitle: Text('Speak: ${lang.isSpeak ? "Yes" : "No"}, Read: ${lang.isRead ? "Yes" : "No"}, Write: ${lang.isWrite ? "Yes" : "No"}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editLanguage(index)),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removeLanguage(index)),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addLanguage() => _showLangDialog();
  void _editLanguage(int index) => _showLangDialog(index: index);
  void _removeLanguage(int index) => setState(() => _langDetails.removeAt(index));

  void _showLangDialog({int? index}) {
    final lang = index != null ? _langDetails[index] : null;
    final langController = TextEditingController(text: lang?.language);
    bool isSpeak = lang?.isSpeak ?? false;
    bool isRead = lang?.isRead ?? false;
    bool isWrite = lang?.isWrite ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Add Language' : 'Edit Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Language', langController),
                CheckboxListTile(
                  title: const Text('Speak'),
                  value: isSpeak,
                  onChanged: (val) => setDialogState(() => isSpeak = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Read'),
                  value: isRead,
                  onChanged: (val) => setDialogState(() => isRead = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Write'),
                  value: isWrite,
                  onChanged: (val) => setDialogState(() => isWrite = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final newLang = LanguageDetail(
                  id: lang?.id ?? "0",
                  language: langController.text,
                  isSpeak: isSpeak,
                  isRead: isRead,
                  isWrite: isWrite,
                );
                setState(() {
                  if (index == null) {
                    _langDetails.add(newLang);
                  } else {
                    _langDetails[index] = newLang;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, {StateSetter? setState}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            final formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
            if (setState != null) {
              setState(() {
                controller.text = formattedDate;
              });
            } else {
              this.setState(() {
                controller.text = formattedDate;
              });
            }
          }
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUploadField(String label, TextEditingController? controller, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller != null)
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickAndUpload(type),
              icon: const Icon(Icons.upload_file),
              label: Text(controller == null ? 'Upload $label' : 'Upload $label Document'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    // Ensure value is in items, or null
    final selectedValue = items.contains(value) ? value : null;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        items: items.isEmpty 
          ? (value != null && value.isNotEmpty ? [DropdownMenuItem(value: value, child: Text(value))] : [])
          : items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (val) {
          if (val == null || val.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }
}
