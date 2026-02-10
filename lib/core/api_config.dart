class ApiConfig {
  static const String baseUrl = "https://smartpayapi.arasoftpeoplehub.com/";
  
  // Endpoints
  static const String login = "api/home/gomain_emp";
  static const String dashboard = "api/empdashboard/getlist";
  static const String team = "api/home/getTeam";
  static const String approvalStatus = "api/attn/GetEmpAppStatus";
  static const String attendanceHistory = "api/empattnhistory/view";
  static const String attendanceDates = "api/empattnhistory/getlist";
  static const String payslipLookup = "api/emppayslip/getlist";
  static const String payslipView = "api/emppayslip/payslipSingle";
  static const String shiftSchedule = "api/empshift/getlist";
  static const String profile = "api/essemp/display";
  static const String profileLookup = "api/empdet/getctccalctotalonly";
  static const String profileSubmit = "api/essemp/submit";
  static const String profilePhotoUpload = "api/essemp/EmpPhotoUpload";
  static const String profilePanUpload = "api/essemp/PanUpload";
  static const String profileAdharUpload = "api/essemp/AdharUpload";
  static const String profileDLUpload = "api/essemp/DLUpload";
  static const String profilePassportUpload = "api/essemp/PassportUpload";
  static const String profileCardUpload = "api/essemp/CardUpload";
  static const String wagesLookup = "api/empdet/getlookupwages";
  static const String wagesSubmit = "api/empdet/submitdet";
  static const String wagesAddNewSalary = "api/empdet/AddNewSalary";
  static const String punchIn = "api/home/setcheckin";
  static const String requestRights = "api/attn/GetESSReqRights";
}
