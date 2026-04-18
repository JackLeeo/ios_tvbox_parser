extension StringExtension on String {
  String get clean => trim().replaceAll(RegExp(r'\s+'), ' ');

  bool get isBase64 => RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(this);
}
