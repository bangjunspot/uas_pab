import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url {
    final raw = (dotenv.env['SUPABASE_URL'] ?? '').trim();
    if (raw.isEmpty) return '';

    // Accept either project base URL or accidental REST endpoint URL.
    final normalized = raw.replaceAll(RegExp(r'/+$'), '');
    final restIndex = normalized.indexOf('/rest/v1');
    if (restIndex != -1) {
      return normalized.substring(0, restIndex);
    }
    return normalized;
  }

  static String get anonKey => (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
}
