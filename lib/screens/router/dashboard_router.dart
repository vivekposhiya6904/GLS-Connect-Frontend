import 'package:flutter/material.dart';
import '../../utils/storage_service.dart';
import '../navigation/main_navigation.dart';
import '../dashboard/admin_home_screen.dart';

class DashboardRouter extends StatefulWidget {
  const DashboardRouter({super.key});

  @override
  State<DashboardRouter> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardRouter> {

  String? role;

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    final savedRole = await StorageService.getUserRole();
    setState(() {
      role = savedRole;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role!.toUpperCase() == "ADMIN") {
      return const AdminHomeScreen();
    }

    return MainNavigation(userRole: role!);
  }
}
