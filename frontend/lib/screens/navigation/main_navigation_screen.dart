import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/session_manager.dart';
import '../components/component_list_screen.dart';
import '../loans/borrow_request_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await SessionManager.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  int _catalogRefreshKey = 0;
  int _loansRefreshKey = 0;

  List<Widget> get _screens => [
    ComponentListScreen(key: ValueKey('catalog_$_catalogRefreshKey')),
    BorrowRequestScreen(key: ValueKey('loans_$_loansRefreshKey')),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
              if (index == 0) _catalogRefreshKey++;
              if (index == 1) _loansRefreshKey++;
            });
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.18),
          elevation: 4,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
              label: 'Katalog Modul',
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined, color: AppColors.textSecondary),
              selectedIcon: const Icon(Icons.assignment, color: AppColors.primary),
              label: _userRole == 'assistant' ? 'Antrean Pinjam' : 'Peminjaman',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profil & Lab',
            ),
          ],
        ),
      ),
    );
  }
}
