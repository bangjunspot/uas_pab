import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../../models/profile.dart';

class AuthService {
  final _supabase = SupabaseService();

  SupabaseClient get _client => _supabase.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) return;

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': email,
      'role': 'kasir',
    });
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile> fetchOrCreateProfile(String userId, String email) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data != null) {
      return Profile.fromMap(data);
    }

    await _client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'role': 'kasir',
      'store_lat': null,
      'store_lng': null,
    });

    final created = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromMap(created);
  }

  Future<List<Profile>> fetchProfiles() async {
    final data = await _client.from('profiles').select().order('email');
    return (data as List)
        .map((item) => Profile.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
  }
}
