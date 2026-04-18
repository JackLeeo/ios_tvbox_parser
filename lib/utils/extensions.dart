extension StringExtension on String {
  String get clean => trim().replaceAll(RegExp(r'\s+'), ' ');
}
