import 'package:flutter/material.dart';
import '../services/source_parser.dart';
import '../services/storage_service.dart';
import '../utils/extensions.dart';
import 'home_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _controller = TextEditingController();
  final StorageService _storage = StorageService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSource();
  }

  void _loadSavedSource() {
    final savedUrl = _storage.getSourceUrl();
    final savedContent = _storage.getSourceContent();
    if (savedUrl != null) {
      _controller.text = savedUrl;
    } else if (savedContent != null) {
      _controller.text = savedContent;
    }
  }

  Future<void> _saveAndApply() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入配置源')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 验证解析
      final config = await SourceParser().parseSource(input);
      
      // 保存
      if (input.startsWith('http://') || input.startsWith('https://')) {
        await _storage.saveSourceUrl(input);
        await _storage.saveSourceContent(''); // 清空旧内容
      } else {
        await _storage.saveSourceContent(input);
        await _storage.saveSourceUrl(''); // 清空旧URL
      }

      if (mounted) {
        // 跳转到主页并传递配置
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(config: config, sourceInput: input),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解析失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置配置源')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '请输入 TVBox 配置源\n（支持 URL 或 Base64 编码内容）',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '例如：https://xxx.com/source.json\n或 Base64 编码的配置',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveAndApply,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('保存并进入'),
                  ),
          ],
        ),
      ),
    );
  }
}
