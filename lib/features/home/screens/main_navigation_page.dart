import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/features/admin/screens/admin_home_page.dart';
import 'package:dia_plus/features/doctor/screens/doctor_home_page.dart';
import 'package:dia_plus/features/doctor/screens/doctor_appointments_page.dart';
import 'package:dia_plus/features/patient/screens/patient_home_page.dart';
import 'package:dia_plus/features/patient/screens/patient_profile_section_page.dart';
import 'package:dia_plus/features/patient/screens/history_page.dart';
import 'package:dia_plus/features/patient/screens/readings_page.dart';
import 'package:dia_plus/features/shared/screens/notifications_page.dart';
import 'package:dia_plus/features/shared/screens/settings_page.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/services/announcement_service.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/doctor_profile_service.dart';
import 'package:dia_plus/services/notification_service.dart';
import 'package:dia_plus/features/doctor/screens/doctor_profile_setup_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main navigation with bottom bar. Content varies by user role.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _authService = AuthService();
  final _doctorProfileService = DoctorProfileService();
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getAppUser();
    if (user != null && user.blocked) {
      await _authService.signOut();
      if (!mounted) return;
      AppRouter.goToStart(context);
      return;
    }
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final existingName = prefs.getString('userName');
      if (existingName == null || existingName.isEmpty) {
        await prefs.setString('userName', user.displayName);
        if (user.initials.isNotEmpty) {
          await prefs.setString('userInitials', user.initials);
        }
      }

      // Doctors must complete their profile before using the app.
      if (user.isDoctor) {
        final profile = await _doctorProfileService.getProfile(user.uid);
        if (profile == null || !profile.isProfileComplete) {
          if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const DoctorProfileSetupPage(isInitialSetup: true),
              ),
            );
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'Session expired. Please log in again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => AppRouter.goToStart(context),
                  icon: Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final homePage = user.isPatient
        ? const PatientHomePage()
        : user.isDoctor
        ? const DoctorHomePage()
        : const AdminHomePage();

    final List<Widget> pages = [
      homePage,
      user.isPatient
          ? const ReadingsPage()
          : const DoctorAppointmentsPage(),
      user.isPatient
          ? const HistoryPage()
          : const Center(child: Text('History - Coming Soon')),
      const NotificationsPage(),
      user.isPatient
          ? PatientProfileSectionPage(user: user)
          : SettingsPage(user: user),
    ];

    return _NavScaffold(user: user, pages: pages);
  }
}

class _NavScaffold extends StatefulWidget {
  const _NavScaffold({required this.user, required this.pages});

  final AppUser user;
  final List<Widget> pages;

  @override
  State<_NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<_NavScaffold> {
  int _currentIndex = 0;

  final _notificationService = NotificationService();
  final _announcementService = AnnouncementService();

  StreamController<int>? _updatesCountController;
  Stream<int>? _updatesCountStream;

  @override
  void initState() {
    super.initState();
    _initializeUpdatesStream(
      uid: widget.user.uid,
      role: widget.user.role.value,
    );
  }

  void _initializeUpdatesStream({required String uid, required String role}) {
    _updatesCountController?.close();
    final controller = StreamController<int>();
    _updatesCountController = controller;
    _updatesCountStream = _buildUpdatesCountStream(
      controller: controller,
      uid: uid,
      role: role,
    );
  }

  @override
  void didUpdateWidget(covariant _NavScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUid = oldWidget.user.uid;
    final oldRole = oldWidget.user.role.value;
    final newUid = widget.user.uid;
    final newRole = widget.user.role.value;
    if (oldUid != newUid || oldRole != newRole) {
      _initializeUpdatesStream(uid: newUid, role: newRole);
    }
  }

  @override
  void dispose() {
    _updatesCountController?.close();
    super.dispose();
  }

  Stream<int> _buildUpdatesCountStream({
    required StreamController<int> controller,
    required String uid,
    required String role,
  }) {
    StreamSubscription<int>? notifSub;
    StreamSubscription<int>? annSub;
    var notifCount = 0;
    var annCount = 0;

    void emit() {
      if (!controller.isClosed) {
        controller.add(notifCount + annCount);
      }
    }

    controller.onListen = () {
      notifSub = _notificationService.streamUnreadCount(uid).listen(
        (value) {
          notifCount = value;
          emit();
        },
        onError: controller.addError,
      );

      annSub = _announcementService.streamUnreadCount(uid: uid, role: role).listen(
        (value) {
          annCount = value;
          emit();
        },
        onError: controller.addError,
      );
    };

    controller.onCancel = () async {
      await notifSub?.cancel();
      await annSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return StreamBuilder<int>(
      stream: _updatesCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        final updatesCount = snapshot.data ?? 0;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardTintLavenderColor(context),
                    border: Border(
                      right: BorderSide(color: AppTheme.borderColor(context)),
                    ),
                  ),
                  child: SafeArea(
                    child: NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        if (!mounted) return;
                        setState(() => _currentIndex = index);
                      },
                      backgroundColor: AppTheme.cardTintLavenderColor(context),
                      selectedIconTheme: const IconThemeData(color: AppTheme.primaryMint),
                      unselectedIconTheme: IconThemeData(
                        color: AppTheme.textSecondaryColor(context),
                      ),
                      selectedLabelTextStyle: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      unselectedLabelTextStyle: Theme.of(context).textTheme.labelSmall,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        const NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(
                            widget.user.isPatient
                                ? Icons.analytics_outlined
                                : Icons.schedule_outlined,
                          ),
                          selectedIcon: Icon(
                            widget.user.isPatient
                                ? Icons.analytics_rounded
                                : Icons.schedule,
                          ),
                          label: Text(
                            widget.user.isPatient ? 'Readings' : 'Schedule',
                          ),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.history_outlined),
                          selectedIcon: Icon(Icons.history),
                          label: Text('History'),
                        ),
                        NavigationRailDestination(
                          icon: _BadgeIcon(
                            icon: Icons.notifications_outlined,
                            count: updatesCount,
                          ),
                          selectedIcon: _BadgeIcon(
                            icon: Icons.notifications,
                            count: updatesCount,
                          ),
                          label: const Text('Updates'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: widget.pages[_currentIndex]),
              ],
            ),
          );
        }

        return Scaffold(
          body: widget.pages[_currentIndex],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  if (!mounted) return;
                  setState(() => _currentIndex = index);
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppTheme.cardTintLavenderColor(context),
                selectedItemColor: AppTheme.primaryMint,
                unselectedItemColor: AppTheme.textSecondaryColor(context),
                selectedLabelStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      widget.user.isPatient
                          ? Icons.analytics_outlined
                          : Icons.schedule_outlined,
                    ),
                    activeIcon: Icon(
                      widget.user.isPatient
                          ? Icons.analytics_rounded
                          : Icons.schedule,
                    ),
                    label: widget.user.isPatient ? 'Readings' : 'Schedule',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: _BadgeIcon(
                      icon: Icons.notifications_outlined,
                      count: updatesCount,
                    ),
                    activeIcon: _BadgeIcon(
                      icon: Icons.notifications,
                      count: updatesCount,
                    ),
                    label: 'Updates',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.softError,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

