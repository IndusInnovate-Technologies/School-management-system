/// All backend endpoints centralized
class Endpoints {
  // Base URL - Update this to match your Django backend
  static const String baseUrl = 'http://localhost:8000/api';

  // Authentication endpoints
  static const String login = '/auth/login/';
  static const String roleLogin = '/auth/role-login/';
  static const String logout = '/auth/logout/';
  static const String refreshToken = '/auth/refresh/';
  static const String register = '/auth/register/';
  static const String routes = '/auth/routes/';
  static const String createPassword = '/auth/create-password/';
  static const String requestOtp = '/auth/request-otp/';
  static const String resetPasswordOtp = '/auth/reset-password-otp/';
  static const String changePassword = '/auth/change-password/';
  static const String financialUsers = '/management-admin/financial-users/';

  // Admin endpoints
  static const String adminSchools = '/super-admin/schools/';
  static const String adminSchoolDetails = '/super-admin/schools/{id}/';
  static const String adminRevenue = '/admin/revenue';
  static const String adminBilling = '/admin/billing';
  static const String supportTickets = '/super-admin/support-tickets/';

  // Management endpoints
  static const String students = '/management-admin/students/';
  static const String teachers = '/management-admin/teachers/';
  static const String departments = '/management-admin/departments/';
  static const String files = '/management-admin/files/';
  static const String buses = '/management-admin/buses/';
  static const String busStops = '/management-admin/bus-stops/';
  static const String busStopStudents = '/management-admin/bus-stop-students/';
  static const String busRoutes = '/management/bus-routes';
  static const String fees = '/management-admin/fees/';
  static const String admissions = '/management-admin/admissions/';
  static const String examinations = '/management-admin/examinations/';
  static const String events = '/management-admin/events/';
  static const String activities = '/management-admin/activities/';
  static const String awards = '/management-admin/awards/';
  static const String campusFeatures = '/management-admin/campus-features/';
  static const String gallery = '/management-admin/galleries/';
  static const String timetables = '/management-admin/timetables/';
  static const String notifications = '/management/notifications';
  static const String calendar = '/management/calendar';
  static const String campusLife = '/management/campus-life';

  // Teacher endpoints
  static const String teacherClasses = '/teacher/classes/';
  static const String teacherStudents = '/teacher/students/';
  static const String teacherTimetable = '/teacher/timetable/';
  static const String teacherExams = '/teacher/exams/';
  static const String teacherHomework = '/teacher/homework/';
  static const String teacherGrades = '/teacher/grades/';
  static const String teacherAttendance = '/teacher/attendance/';
  static const String teacherAssignment = '/teacher/assignments/';
  static const String teacherStudyMaterial = '/teacher/study-material/';
  static const String teacherCommunication = '/teacher/communication/';
  static const String teacherResults = '/teacher/results/';
  static const String teacherProfile = '/teacher/profile/';
  static const String teacherTimetableTemplate = '/teacher/timetables/template/';
  static const String teacherTimetableImport = '/teacher/timetables/import/';

  // Parent endpoints
  static const String parentDashboard = '/parent/dashboard';
  static const String parentProfile = '/parent/profile';
  static const String parentAcademics = '/parent/academics';
  static const String parentResults = '/parent/results';
  static const String parentTests = '/parent/tests';
  static const String parentProjects = '/parent/projects';
  static const String parentHomework = '/student-parent/dashboard/homework/';
  static const String parentDailyTask = '/parent/daily-tasks';
  static const String parentCalendar = '/parent/calendar';
  static const String parentGallery = '/parent/gallery';
  static const String parentBus = '/parent/bus';
  static const String parentFees = '/parent/fees';
  static const String parentExtracurricular = '/parent/extracurricular';

  // Helper method to build full URL
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method to replace path parameters
  static String replacePathParam(String endpoint, String param, String value) {
    return endpoint.replaceAll('{$param}', value);
  }
}

