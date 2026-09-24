import 'package:flutter/material.dart';
import '../models/user.dart';
import 'home/home_screen.dart';
import 'rider/rider_home_screen.dart';

/// Picks the right experience for a signed-in user: riders get the delivery
/// app, everyone else gets the customer app.
Widget homeForUser(AppUser? user) =>
    user?.isRider == true ? const RiderHomeScreen() : const HomeScreen();
