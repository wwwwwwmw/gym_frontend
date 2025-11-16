import 'package:flutter/material.dart';
import 'package:gym_frontend/app.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  runApp(const GymApp());
}
