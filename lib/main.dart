import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_todo_app_refactored/providers/todo_provider.dart';
import 'package:flutter_todo_app_refactored/services/notification_service.dart';
import 'package:flutter_todo_app_refactored/screens/home_screen.dart';
import 'package:flutter_todo_app_refactored/utils/app_theme.dart';
import 'package:flutter_todo_app_refactored/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}


