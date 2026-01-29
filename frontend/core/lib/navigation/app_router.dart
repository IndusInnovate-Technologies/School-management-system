import 'package:flutter/material.dart';

/// All navigations here (NO navigators in UI)
class AppRouter {
  // Route names
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String adminLogin = '/admin-login';
  static const String managementLogin = '/management-login';
  static const String teacherLogin = '/teacher-login';
  static const String parentLogin = '/parent-login';

  // Admin routes
  static const String adminSchools = '/admin/schools';
  static const String adminSchoolDetails = '/admin/schools/details';
  static const String adminAddSchool = '/admin/schools/add';
  static const String adminRevenue = '/admin/revenue';
  static const String adminBilling = '/admin/billing';

  // Management routes
  static const String students = '/management/students';
  static const String addStudent = '/management/students/add';
  static const String editStudent = '/management/students/edit';
  static const String teachers = '/management/teachers';
  static const String addTeacher = '/management/teachers/add';
  static const String editTeacher = '/management/teachers/edit';
  static const String departments = '/management/departments';
  static const String buses = '/management/buses';
  static const String addBus = '/management/buses/add';
  static const String editBus = '/management/buses/edit';
  static const String busRoutes = '/management/bus-routes';
  static const String fees = '/management/fees';
  static const String admissions = '/management/admissions';
  static const String examinations = '/management/examinations';
  static const String events = '/management/events';
  static const String activities = '/management/activities';
  static const String addActivity = '/management/activities/add';
  static const String editActivity = '/management/activities/edit';
  static const String awards = '/management/awards';
  static const String gallery = '/management/gallery';
  static const String notifications = '/management/notifications';
  static const String calendar = '/management/calendar';
  static const String campusLife = '/management/campus-life';

  // Teacher routes
  static const String teacherClasses = '/teacher/classes';
  static const String teacherClassStudents = '/teacher/classes/students';
  static const String teacherProfile = '/teacher/profile';
  static const String teacherTimetable = '/teacher/timetable';
  static const String teacherExam = '/teacher/exam';
  static const String teacherGrades = '/teacher/grades';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherAssignment = '/teacher/assignment';
  static const String teacherStudyMaterial = '/teacher/study-material';
  static const String teacherCommunication = '/teacher/communication';
  static const String teacherResults = '/teacher/results';

  // Parent routes
  static const String parentDashboard = '/parent/dashboard';
  static const String parentProfile = '/parent/profile';
  static const String parentAcademics = '/parent/academics';
  static const String parentResults = '/parent/results';
  static const String parentTests = '/parent/tests';
  static const String parentProjects = '/parent/projects';
  static const String parentHomework = '/parent/homework';
  static const String parentDailyTask = '/parent/daily-task';
  static const String parentCalendar = '/parent/calendar';
  static const String parentGallery = '/parent/gallery';
  static const String parentBus = '/parent/bus';
  static const String parentFees = '/parent/fees';
  static const String parentExtracurricular = '/parent/extracurricular';

  // Navigation methods
  static void push(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  static void pushReplacement(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  static void pushAndRemoveUntil(
    BuildContext context,
    String route, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }

  static void popUntil(BuildContext context, String route) {
    Navigator.popUntil(context, ModalRoute.withName(route));
  }

  static Future<T?>? pushRoute<T>(
    BuildContext context,
    Widget page, {
    bool fullscreenDialog = false,
  }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  static void pushReplacementRoute(
    BuildContext context,
    Widget page,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Helper to get route arguments
  static T? getArguments<T>(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is T ? args : null;
  }

  // Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}

