import 'package:flutter/material.dart';

import 'management_routes.dart';

// Import screens
import 'dashboard.dart';
import 'students.dart';
import 'teachers.dart';
import 'gallery.dart';
import 'buses.dart';
import 'events.dart';
import 'notifications.dart';
import 'calendar.dart';
import 'activities.dart';
import 'examinations.dart';
import 'fees.dart';
import 'admissions.dart';
import 'departments.dart';
import 'awards.dart';
import 'campus_life.dart';
import 'rti_act.dart';
import 'add_teacher.dart';
import 'edit_student.dart';
import 'edit_teacher.dart';
import 'edit_bus.dart';
import 'edit_activity.dart';
import 'add_newactivity.dart';
import 'add_newBus.dart';
import 'add_event.dart';
import 'edit_event.dart';
import 'pages/support_request_page.dart';
import 'financial_profiles.dart';
import 'financial_dashboard.dart';



class ManagementRoutePages {
  static Map<String, WidgetBuilder> routes = {
    ManagementRoutes.dashboard: (_) => const DashboardPage(),
    ManagementRoutes.students: (_) => const StudentsManagementPage(),
    ManagementRoutes.teachers: (_) => const TeachersManagementPage(),
    ManagementRoutes.buses: (_) => const BusesManagementPage(),
    ManagementRoutes.gallery: (_) => const PhotoGalleryPage(),
    ManagementRoutes.events: (_) => const EventsManagementPage(),
    ManagementRoutes.notifications: (_) => const NotificationsManagementPage(),
    ManagementRoutes.calendar: (_) => const CalendarManagementPage(),
    ManagementRoutes.activities: (_) => const ActivitiesManagementPage(),
    ManagementRoutes.examinations: (_) => const ExaminationManagementPage(),
    ManagementRoutes.fees: (_) => const FeesManagementPage(),
    ManagementRoutes.admissions: (_) => const AdmissionsManagementPage(),
    ManagementRoutes.departments: (_) => const DepartmentsManagementPage(),
    ManagementRoutes.awards: (_) => const AwardsManagementPage(),
    ManagementRoutes.financialDashboard: (_) => const FinancialDashboardPage(),
    ManagementRoutes.financialProfiles: (_) => const FinancialProfilesPage(),
    ManagementRoutes.rtiAct: (_) => const RTIActPage(),
    ManagementRoutes.busRoutes: (_) => const BusesManagementPage(), // Mapping bus-routes to Buses page
    ManagementRoutes.campusLife: (_) => const CampusLifeManagementPage(),
    ManagementRoutes.addTeacher: (_) => const AddTeacherPage(),
    ManagementRoutes.editStudent: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final studentId = args is int ? args : null;
      return EditStudentPage(studentId: studentId);
    },
    ManagementRoutes.editTeacher: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final employeeNo = args is String ? args : null;
      return EditTeacherPage(employeeNo: employeeNo);
    },
    ManagementRoutes.editBus: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final busId = args is String ? args : (args is int ? args.toString() : null);
      return EditBusPage(busId: busId);
    },
    ManagementRoutes.editActivity: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final activityId = args is int ? args : null;
      return EditActivityPage(activityId: activityId);
    },
    ManagementRoutes.addActivity: (_) => const AddNewActivityPage(),
    ManagementRoutes.addNewBus: (_) => const AddNewBusPage(),
    ManagementRoutes.addEvent: (_) => const AddEventPage(),
    ManagementRoutes.editEvent: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final eventId = args is int ? args : null;
      return EditEventPage(eventId: eventId);
    },
    ManagementRoutes.supportRequest: (_) => const SupportRequestPage(),
  };
}


