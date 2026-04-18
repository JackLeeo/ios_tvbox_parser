import 'package:flutter/material.dart';
import 'pages/settings_page.dart';
import 'services/storage_service.dart';
import 'services/node_parser_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();

  // 启动 Node.js 引擎（不等待，避免白屏）
  NodeParserService().init().catchError((e) {
    print('Node.js 启动失败: $e，将使用公共解析接口');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TVBox',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
      ),
      home: const SettingsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
