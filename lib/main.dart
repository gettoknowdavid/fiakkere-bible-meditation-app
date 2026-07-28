import 'package:fiakkere/app.dart';
import 'package:fiakkere/locator.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const FiakKereApp());
}
