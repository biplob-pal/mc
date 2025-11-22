import 'package:flutter/material.dart';
import 'package:medicine_dispersor/screens/medication_list_screen.dart';
import 'package:medicine_dispersor/screens/schedule_screen.dart';
import 'package:medicine_dispersor/screens/connectivity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<MedicationListScreenState> _medicationListKey = GlobalKey<MedicationListScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MedicationListScreen(key: _medicationListKey),
      const ScheduleScreen(),
      const ConnectivityScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Dispersor'),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi),
            label: 'Connectivity',
          ),
        ],
      ),
    );
  }
}