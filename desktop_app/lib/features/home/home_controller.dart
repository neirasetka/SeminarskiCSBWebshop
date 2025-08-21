import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeMessageProvider = Provider<String>((ProviderRef<String> ref) {
  return 'Welcome to the Home page!';
});