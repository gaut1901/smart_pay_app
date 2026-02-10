class ProfileModel {
  final String? empCode;
  final String? prefix;
  final String? empName;
  final String? empFName;
  final String? empMiddleName;
  final String? empLName;
  final String? fName;
  final String? hName;
  final String? sex;
  final String? mStatus;
  final String? bloodGroup;
  final String? dob;
  final String? address;
  final String? city;
  final String? pinCode;
  final String? stateName;
  final String? countryName;
  final bool sameAddress;
  final String? comAddress;
  final String? comCity;
  final String? comPinCode;
  final String? comStateName;
  final String? comCountryName;
  final String? phoneNo;
  final String? mobileNo;
  final String? emailId;
  final String? officeEmail;
  final String? cugNo;
  final String? reliName;
  final String? nationality;
  final String? panNo;
  final String? adharNo;
  final String? passportNo;
  final String? dlNo;
  final String? insuranceNo;
  final String? uanNo;
  final String? pfNo;
  final String? esiNo;
  final String? bankName;
  final String? accountNo;
  final String? ifsCode;
  final String? desName;
  final String? deptName;
  final String? locName;
  final String? catName;
  final String? doj;
  final String? hodName;
  final String? eContactName;
  final String? eContactNumber;
  final String? eContactRelation;
  final String? dlExpDate;
  final String? passportExpDate;
  final String? medicalIssues;
  final String? editId;
  final String? actions;
  final String? ctc;
  final String? incDate;

  final bool isResign;
  final String? resignDate;
  final String? resignReasonHead;
  final String? resignReason;

  final bool empPortal;
  final String? userName;
  final String? password;

  final String? photoBase64;
  final String? panBase64;
  final String? adharBase64;
  final String? passportBase64;
  final String? dlBase64;
  final String? insuranceBase64;

  final List<EducationDetail> eduDetails;
  final List<ExperienceDetail> expDetails;
  final List<InsuranceDetail> insDetails;
  final List<LanguageDetail> langDetails;
  final List<FamilyDetail> familyDetails;
  final List<PFNomineeDetail> pfNominees;
  final List<dynamic> dtEarn;
  final List<dynamic> dtDed;
  final List<dynamic> dtPFDet;

  ProfileModel({
    this.empCode,
    this.prefix,
    this.empName,
    this.empFName,
    this.empMiddleName,
    this.empLName,
    this.fName,
    this.hName,
    this.sex,
    this.mStatus,
    this.bloodGroup,
    this.dob,
    this.address,
    this.city,
    this.pinCode,
    this.stateName,
    this.countryName,
    this.sameAddress = false,
    this.comAddress,
    this.comCity,
    this.comPinCode,
    this.comStateName,
    this.comCountryName,
    this.phoneNo,
    this.mobileNo,
    this.emailId,
    this.officeEmail,
    this.cugNo,
    this.reliName,
    this.nationality,
    this.panNo,
    this.adharNo,
    this.passportNo,
    this.dlNo,
    this.insuranceNo,
    this.uanNo,
    this.pfNo,
    this.esiNo,
    this.bankName,
    this.accountNo,
    this.ifsCode,
    this.desName,
    this.deptName,
    this.locName,
    this.catName,
    this.doj,
    this.hodName,
    this.eContactName,
    this.eContactNumber,
    this.eContactRelation,
    this.dlExpDate,
    this.passportExpDate,
    this.medicalIssues,
    this.editId,
    this.actions,
    this.ctc,
    this.incDate,
    this.isResign = false,
    this.resignDate,
    this.resignReasonHead,
    this.resignReason,
    this.empPortal = false,
    this.userName,
    this.password,
    this.photoBase64,
    this.panBase64,
    this.adharBase64,
    this.passportBase64,
    this.dlBase64,
    this.insuranceBase64,
    this.eduDetails = const [],
    this.expDetails = const [],
    this.insDetails = const [],
    this.langDetails = const [],
    this.familyDetails = const [],
    this.pfNominees = const [],
    this.dtEarn = const [],
    this.dtDed = const [],
    this.dtPFDet = const [],
    this.extraData = const {},
  });

  final Map<String, dynamic> extraData;

  dynamic operator [](String key) => extraData[key];

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      empCode: json['EmpCode']?.toString(),
      prefix: json['Prefix']?.toString() ?? json['TicketNoPreFix']?.toString(),
      empName: json['EmpName']?.toString(),
      empFName: json['EmpFName']?.toString(),
      empMiddleName: json['EmpMiddleName']?.toString(),
      empLName: json['EmpLName']?.toString(),
      fName: json['FName']?.toString(),
      hName: json['HName']?.toString(),
      sex: json['Sex']?.toString(),
      mStatus: json['MStatus']?.toString(),
      bloodGroup: json['BloodGroup']?.toString(),
      dob: json['DOB']?.toString(),
      address: json['Address']?.toString(),
      city: json['City']?.toString(),
      pinCode: json['PinCode']?.toString(),
      stateName: json['StateName']?.toString(),
      countryName: json['CountryName']?.toString(),
      sameAddress: json['SameAddress'] == true,
      comAddress: json['ComAddress']?.toString(),
      comCity: json['ComCity']?.toString(),
      comPinCode: json['ComPinCode']?.toString(),
      comStateName: json['ComStateName']?.toString(),
      comCountryName: json['ComCountryName']?.toString(),
      phoneNo: json['PhoneNo']?.toString(),
      mobileNo: json['MobileNo']?.toString(),
      emailId: json['EmailId']?.toString(),
      officeEmail: json['OfficeEmail']?.toString(),
      cugNo: json['CUGNo']?.toString(),
      reliName: json['ReliName']?.toString(),
      nationality: json['Nationality']?.toString(),
      panNo: json['PanNo']?.toString(),
      adharNo: json['AdharNo']?.toString(),
      passportNo: json['PassportNo']?.toString(),
      dlNo: json['DLNo']?.toString(),
      insuranceNo: json['InsuranceNo']?.toString(),
      uanNo: json['UANNo']?.toString(),
      pfNo: json['PFNo']?.toString(),
      esiNo: json['ESINo']?.toString(),
      bankName: json['BankName']?.toString(),
      accountNo: json['AccountNo']?.toString(),
      ifsCode: json['IFSCode']?.toString(),
      desName: json['DesName']?.toString(),
      deptName: json['DeptName']?.toString(),
      locName: json['LocName']?.toString(),
      catName: json['CatName']?.toString(),
      doj: json['DOJ']?.toString(),
      hodName: json['HODName']?.toString(),
      eContactName: json['EContactName']?.toString(),
      eContactNumber: json['EContactNumber']?.toString(),
      eContactRelation: json['EContactRelation']?.toString(),
      dlExpDate: json['DLExpDate']?.toString(),
      passportExpDate: json['PassportExpDate']?.toString(),
      medicalIssues: json['MedicalIssues']?.toString(),
      editId: json['EditId']?.toString(),
      actions: json['Actions']?.toString(),
      ctc: json['CTC']?.toString(),
      incDate: json['IncDate']?.toString(),
      isResign: json['IsResign'] == true || json['IsResign'] == 'true',
      resignDate: json['ResignDate']?.toString(),
      resignReasonHead: json['ResignReasonHead']?.toString(),
      resignReason: json['ResignReason']?.toString(),
      empPortal: json['EmpPortal'] == true || json['EmpPortal'] == 'true',
      userName: json['UserName']?.toString(),
      password: json['Password']?.toString(),
      photoBase64: json['PhotoBase64']?.toString(),
      panBase64: json['PanBase64']?.toString(),
      adharBase64: json['AdharBase64']?.toString(),
      passportBase64: json['PassportBase64']?.toString(),
      dlBase64: json['DLBase64']?.toString(),
      insuranceBase64: json['InsuranceBase64']?.toString(),
      eduDetails: (json['dtEduDetails'] as List? ?? json['dtEduDet'] as List? ?? [])
          .map((e) => EducationDetail.fromJson(e))
          .toList(),
      expDetails: (json['dtExpDetail'] as List? ?? json['dtExpDet'] as List? ?? [])
          .map((e) => ExperienceDetail.fromJson(e))
          .toList(),
      insDetails: (json['dtInsDet'] as List? ?? [])
          .map((e) => InsuranceDetail.fromJson(e))
          .toList(),
      langDetails: (json['dtLangDet'] as List? ?? [])
          .map((e) => LanguageDetail.fromJson(e))
          .toList(),
      familyDetails: (json['dtFamilyMembers'] as List? ?? json['dtFamilyDet'] as List? ?? [])
          .map((e) => FamilyDetail.fromJson(e))
          .toList(),
      pfNominees: (json['dtPFDet'] as List? ?? [])
          .map((e) => PFNomineeDetail.fromJson(e))
          .toList(),
      dtEarn: json['dtEarn'] as List? ?? [],
      dtDed: json['dtDed'] as List? ?? [],
      dtPFDet: json['dtPFDet'] as List? ?? [],
      extraData: json,
    );
  }

  Map<String, dynamic> toJson() {
    final map = Map<String, dynamic>.from(extraData);
    map.addAll({
      "EmpCode": empCode,
      "TicketNoPreFix": prefix,
      "EmpName": empName,
      "EmpFName": empFName,
      "EmpMiddleName": empMiddleName,
      "EmpLName": empLName,
      "FName": fName,
      "HName": (mStatus == 'Married') ? hName : "",
      "Sex": sex,
      "MStatus": mStatus,
      "BloodGroup": bloodGroup,
      "DOB": dob,
      "Address": address,
      "City": city,
      "PinCode": pinCode,
      "StateName": stateName,
      "CountryName": countryName,
      "SameAddress": sameAddress,
      "ComAddress": comAddress,
      "ComCity": comCity,
      "ComPinCode": comPinCode,
      "ComStateName": comStateName,
      "ComCountryName": comCountryName,
      "PhoneNo": phoneNo,
      "MobileNo": mobileNo,
      "EmailId": emailId,
      "OfficeEmail": officeEmail,
      "CUGNo": cugNo,
      "ReliName": reliName,
      "Nationality": nationality,
      "PanNo": panNo,
      "AdharNo": adharNo,
      "PassportNo": passportNo,
      "DLNo": dlNo,
      "InsuranceNo": insuranceNo,
      "UANNo": uanNo,
      "PFNo": pfNo,
      "ESINo": esiNo,
      "BankName": bankName,
      "AccountNo": accountNo,
      "IFSCode": ifsCode,
      "DesName": desName,
      "DeptName": deptName,
      "LocName": locName,
      "CatName": catName,
      "DOJ": doj,
      "HODName": hodName,
      "EContactName": eContactName,
      "EContactNumber": eContactNumber,
      "EContactRelation": eContactRelation,
      "DLExpDate": dlExpDate,
      "PassportExpDate": passportExpDate,
      "MedicalIssues": medicalIssues,
      "EditId": editId,
      "Actions": actions,
      "CTC": ctc,
      "IncDate": incDate,
      "IsResign": isResign,
      "ResignDate": resignDate,
      "ResignReasonHead": resignReasonHead,
      "ResignReason": resignReason,
      "EmpPortal": empPortal,
      "UserName": userName,
      "Password": password,
      "PhotoBase64": photoBase64,
      "PanBase64": panBase64,
      "AdharBase64": adharBase64,
      "PassportBase64": passportBase64,
      "DLBase64": dlBase64,
      "InsuranceBase64": insuranceBase64,
      "dtEduDet": eduDetails.map((e) => e.toJson()).toList(),
      "dtExpDet": expDetails.map((e) => e.toJson()).toList(),
      "dtInsDet": insDetails.map((e) => e.toJson()).toList(),
      "dtLangDet": langDetails.map((e) => e.toJson()).toList(),
      "dtFamilyDet": familyDetails.map((e) => e.toJson()).toList(),
      "dtPFDet": pfNominees.map((e) => e.toJson()).toList(),
      "dtEarn": dtEarn,
      "dtDed": dtDed,
    });
    return map;
  }
}

class EducationDetail {
  final String? id;
  final String? degreeType;
  final String? degree;
  final String? institution;
  final String? subject;
  final String? passYear;
  final String? passDate;
  final String? filePath;

  EducationDetail({
    this.id,
    this.degreeType,
    this.degree,
    this.institution,
    this.subject,
    this.passYear,
    this.passDate,
    this.filePath,
  });

  factory EducationDetail.fromJson(Map<String, dynamic> json) {
    return EducationDetail(
      id: json['Id']?.toString() ?? json['EduId']?.toString(),
      degreeType: json['DegreeType']?.toString(),
      degree: json['Degree']?.toString(),
      institution: json['Institution']?.toString(),
      subject: json['Subject']?.toString(),
      passYear: json['PassYear']?.toString(),
      passDate: json['PassDate']?.toString(),
      filePath: json['FilePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "EduId": id,
      "DegreeType": degreeType,
      "Degree": degree,
      "Institution": institution,
      "Subject": subject,
      "PassYear": passYear,
      "PassDate": passDate,
      "FilePath": filePath,
    };
  }
}

class ExperienceDetail {
  final String? id;
  final String? companyName;
  final String? role;
  final String? duration;
  final String? expFrom;
  final String? expTo;
  final String? filePath; // Experience Certificate
  final String? filePath1; // Relieving Order

  ExperienceDetail({
    this.id,
    this.companyName,
    this.role,
    this.duration,
    this.expFrom,
    this.expTo,
    this.filePath,
    this.filePath1,
  });

  factory ExperienceDetail.fromJson(Map<String, dynamic> json) {
    return ExperienceDetail(
      id: json['Id']?.toString() ?? json['ExpId']?.toString(),
      companyName: json['CompanyName']?.toString(),
      role: json['Role']?.toString(),
      duration: json['Duration']?.toString(),
      expFrom: json['ExpFrom']?.toString(),
      expTo: json['ExpTo']?.toString(),
      filePath: json['FilePath']?.toString(),
      filePath1: json['FilePath1']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "ExpId": id,
      "CompanyName": companyName,
      "Role": role,
      "Duration": duration,
      "ExpFrom": expFrom,
      "ExpTo": expTo,
      "FilePath": filePath,
      "FilePath1": filePath1,
    };
  }
}

class InsuranceDetail {
  final String? id;
  final String? insTypeName;
  final String? insuranceName;
  final String? insCompanyName;
  final String? insNo;
  final String? insFor;
  final String? insAmount;
  final String? startDate;
  final String? endDate;
  final String? filePath;

  InsuranceDetail({
    this.id,
    this.insTypeName,
    this.insuranceName,
    this.insCompanyName,
    this.insNo,
    this.insFor,
    this.insAmount,
    this.startDate,
    this.endDate,
    this.filePath,
  });

  factory InsuranceDetail.fromJson(Map<String, dynamic> json) {
    return InsuranceDetail(
      id: json['SlNo']?.toString() ?? json['InsId']?.toString(),
      insTypeName: json['InsTypeName']?.toString(),
      insuranceName: json['InsuranceName']?.toString() ?? json['InsName']?.toString(),
      insCompanyName: json['InsCompanyName']?.toString() ?? json['InsCmpName']?.toString(),
      insNo: json['InsNo']?.toString(),
      insFor: json['InsFor']?.toString(),
      insAmount: json['InsAmount']?.toString(),
      startDate: json['StartDate']?.toString() ?? json['InsStartDate']?.toString(),
      endDate: json['EndDate']?.toString() ?? json['InsEndDate']?.toString(),
      filePath: json['FilePath']?.toString() ?? json['InsFilePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "SlNo": id,
      "InsType": insTypeName,
      "InsTypeName": insTypeName,
      "InsName": insuranceName,
      "InsuranceName": insuranceName,
      "InsCmpName": insCompanyName,
      "InsCompanyName": insCompanyName,
      "InsNo": insNo,
      "InsFor": insFor,
      "InsAmount": insAmount,
      "StartDate": startDate,
      "EndDate": endDate,
      "FilePath": filePath,
    };
  }
}

class LanguageDetail {
  final String? id;
  final String? language;
  final bool isSpeak;
  final bool isRead;
  final bool isWrite;

  LanguageDetail({
    this.id,
    this.language,
    this.isSpeak = false,
    this.isRead = false,
    this.isWrite = false,
  });

  factory LanguageDetail.fromJson(Map<String, dynamic> json) {
    return LanguageDetail(
      id: json['Id']?.toString(),
      language: json['Language']?.toString(),
      isSpeak: json['isSpeak'] == true || json['isSpeak'] == "true",
      isRead: json['isRead'] == true || json['isRead'] == "true",
      isWrite: json['isWrite'] == true || json['isWrite'] == "true",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "Language": language,
      "isSpeak": isSpeak,
      "isRead": isRead,
      "isWrite": isWrite,
    };
  }
}

class FamilyDetail {
  final String? id;
  final String? mName;
  final String? mRelation;
  final String? bloodGroup;
  final String? mobileNo;
  final String? dob;
  final String? adharNo;
  final String? adharPath;
  final String? base64; // Image
  final String? eduDetail;
  final String? occDetail;

  FamilyDetail({
    this.id,
    this.mName,
    this.mRelation,
    this.bloodGroup,
    this.mobileNo,
    this.dob,
    this.adharNo,
    this.adharPath,
    this.base64,
    this.eduDetail,
    this.occDetail,
  });

  factory FamilyDetail.fromJson(Map<String, dynamic> json) {
    return FamilyDetail(
      id: json['Id']?.toString(),
      mName: json['MName']?.toString(),
      mRelation: json['MRelation']?.toString(),
      bloodGroup: json['BloodGroup']?.toString(),
      mobileNo: json['MobileNo']?.toString(),
      dob: json['dob']?.toString() ?? json['MemberDOB']?.toString(),
      adharNo: json['adharno']?.toString() ?? json['MemberAdharNo']?.toString(),
      adharPath: json['adharpath']?.toString() ?? json['MemberAdharPath']?.toString(),
      base64: json['Base64']?.toString() ?? json['FilePath']?.toString(),
      eduDetail: json['EduDetail']?.toString() ?? json['MemberEduDetail']?.toString(),
      occDetail: json['OccDetail']?.toString() ?? json['MemberOccDetail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "MName": mName,
      "MRelation": mRelation,
      "BloodGroup": bloodGroup,
      "MobileNo": mobileNo,
      "dob": dob,
      "adharno": adharNo,
      "adharpath": adharPath,
      "Base64": base64,
      "EduDetail": eduDetail,
      "OccDetail": occDetail,
    };
  }
}

class PFNomineeDetail {
  final String? id;
  final String? memberName;
  final String? shareP;

  PFNomineeDetail({
    this.id,
    this.memberName,
    this.shareP,
  });

  factory PFNomineeDetail.fromJson(Map<String, dynamic> json) {
    return PFNomineeDetail(
      id: json['SlNo']?.toString(),
      memberName: json['MemberName']?.toString(),
      shareP: json['P']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "SlNo": id,
      "MemberName": memberName,
      "P": shareP,
      "ShareP": shareP,
    };
  }
}
