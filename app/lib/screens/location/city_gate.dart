import 'package:flutter/material.dart';
import '../../services/city_store.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import 'select_city_screen.dart';

/// On app open: if no city chosen yet, ask for it; otherwise go to Home.
class CityGate extends StatefulWidget {
  const CityGate({super.key});
  @override
  State<CityGate> createState() => _CityGateState();
}

class _CityGateState extends State<CityGate> {
  bool _loading = true;
  String? _city;

  @override
  void initState() {
    super.initState();
    CityStore.get().then((c) => setState(() {
          _city = c;
          _loading = false;
        }));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    if (_city == null) {
      return SelectCityScreen(onSelected: (c) => setState(() => _city = c));
    }
    return const HomeScreen();
  }
}
