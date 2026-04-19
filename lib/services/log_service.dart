import 'dart:collection';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final _logs = Queue<String>();
  final _maxLogs = 200;

  void add(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logs.add('[$timestamp] $message');
    if (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }
  }

  List<String> getLogs() => _logs.toList();

  void clear() => _logs.clear();

  String export() => _logs.join('\n');
}
