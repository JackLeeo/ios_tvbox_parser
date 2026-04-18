import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/config_service.dart';
import '../models/source.dart';
import 'home_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _controller = TextEditingController();
  final ConfigService _configService = ConfigService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _importAndGo() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = '请输入配置源');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 保存输入内容
      await _configService.saveConfig(input);
      // 测试解析
      final config = await _configService.loadConfig();
      if (config != null) {
        // 解析成功，跳转到主页
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        setState(() => _errorMessage = '配置解析失败，请检查内容');
      }
    } catch (e) {
      setState(() => _errorMessage = '导入失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入配置源')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '请输入TVBox配置源URL或Base64编码的内容',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '粘贴配置源URL或Base64内容...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  label: const Text('粘贴'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (_errorMessage != null)
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _importAndGo,
              icon: _isLoading
                  ? const SpinKitFadingCircle(color: Colors.white, size: 20)
                  : const Icon(Icons.check),
              label: const Text('导入并开始使用'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              '提示：\n- 支持直接输入配置源URL\n- 支持粘贴Base64编码的配置内容\n- 配置将保存在本地，下次启动自动加载',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
