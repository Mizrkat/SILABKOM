import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/session_manager.dart';
import '../components/component_list_screen.dart';
import '../loans/borrow_request_screen.dart';
import '../components/add_component_screen.dart';
import '../archive/archive_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _userRole = 'student';

  int _catalogRefreshKey = 0;
  int _loansRefreshKey = 0;
  int _archiveRefreshKey = 0;

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

  List<Widget> _getScreens(bool isAssistant) {
    if (isAssistant) {
      return [
        ComponentListScreen(key: ValueKey('catalog_$_catalogRefreshKey')),
        BorrowRequestScreen(key: ValueKey('loans_$_loansRefreshKey')),
        AddComponentScreen(
          key: const ValueKey('add_component_screen'),
          isEmbedded: true,
          onModuleAdded: () {
            setState(() {
              _currentIndex = 0;
              _catalogRefreshKey++;
            });
          },
        ),
        ArchiveScreen(
          key: ValueKey('archive_$_archiveRefreshKey'),
          onRestored: () {
            setState(() {
              _catalogRefreshKey++;
              _loansRefreshKey++;
            });
          },
        ),
        const ProfileScreen(),
      ];
    }

    // Role Mahasiswa (TIDAK DIRUBAH SAMA SEKALI)
    return [
      ComponentListScreen(key: ValueKey('catalog_$_catalogRefreshKey')),
      BorrowRequestScreen(key: ValueKey('loans_$_loansRefreshKey')),
      const ProfileScreen(),
    ];
  }

  List<NavigationDestination> _getDestinations(bool isAssistant) {
    if (isAssistant) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
          label: 'Katalog',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
          label: 'Antrean',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.add_circle, color: AppColors.primary),
          label: 'Tambah',
        ),
        NavigationDestination(
          icon: Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.delete_sweep, color: AppColors.primary),
          label: 'Arsip',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Profil',
        ),
      ];
    }

    // Role Mahasiswa
    return const [
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
        selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
        label: 'Katalog',
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined, color: AppColors.textSecondary),
        selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
        label: 'Peminjaman',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
        selectedIcon: Icon(Icons.person, color: AppColors.primary),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isAssistant = _userRole == 'assistant';
    final screens = _getScreens(isAssistant);
    final destinations = _getDestinations(isAssistant);

    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
              if (index == 0) _catalogRefreshKey++;
              if (index == 1) _loansRefreshKey++;
              if (isAssistant && index == 3) _archiveRefreshKey++;
            });
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.18),
          elevation: 4,
          destinations: destinations,
        ),
      ),
    );
  }
}
