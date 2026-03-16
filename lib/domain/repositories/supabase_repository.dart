import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/avatar_config.dart';
import '../models/match.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Auth & User Profile ---

  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    // Attempt to get the profile. If it doesn't exist (e.g., anonymous user or new signup),
    // we return a basic AppUser created from the Auth user data.
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return AppUser.fromJson(response);
      }
    } catch (_) {
      // Ignored, fallback to generating from User
    }

    return AppUser(
      id: user.id,
      name: user.userMetadata?['name'] as String? ?? 'Guest Provider',
      username: 'user_${user.id.substring(0, 6)}',
      totalXP: 0,
      level: 1,
      languageStats: {},
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmail(String email, String password, String username) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': username},
    );
     // Note: In a real app, you might want to create the 'profiles' row here 
     // or let an auth trigger in Supabase handle it.
  }

  Future<void> signInWithGoogle() async {
    // Para Flutter web o desktop, necesitamos decirle a Supabase
    // a qué URL debe redirigir después del inicio de sesión con Google.
    // Usamos la URL actual si estamos en web, o un deep link si estamos en móvil.
    
    String? redirectTo;
    if (kIsWeb) {
      redirectTo = Uri.base.origin;
    } else {
      // Para móvil (Android/iOS), definimos un Deep Link Scheme personalizado
      // que tu aplicación interceptará para volver a abrirse.
      // E.g. com.example.hotpotato://login-callback
      // Este esquema DEBE estar configurado en:
      // 1. AndroidManifest.xml (Android)
      // 2. Info.plist (iOS)
      // 3. Supabase Dashboard -> URL Configuration -> Redirect URLs
      redirectTo = 'com.example.hotpotato://login-callback';
    }

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  Future<void> signInAsGuest() async {
    await _client.auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> updateXP(String userId, int xpToAdd) async {
    final response = await _client
        .from('profiles')
        .select('total_xp')
        .eq('id', userId)
        .single();
    
    final currentXp = response['total_xp'] as int? ?? 0;
    
    await _client.from('profiles').update({
      'total_xp': currentXp + xpToAdd,
    }).eq('id', userId);
  }

  // --- Social Feed ---

  Future<List<Post>> getFeedPosts() async {
    final response = await _client
        .from('posts')
        .select()
        .order('timestamp', ascending: false)
        .limit(20);
    
    return (response as List).map((json) => Post.fromJson(json)).toList();
  }

  Future<void> createPost(String content, {String? imageUrl}) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('Not authenticated');

    await _client.from('posts').insert({
      'author_id': user.id,
      'author_name': user.name,
      'content': content,
      'image_url': imageUrl,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // --- Avatar Customization ---

  Future<AvatarConfig> getAvatarConfig(String userId) async {
    final response = await _client
        .from('user_avatar_config')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) {
      return AvatarConfig(userId: userId); // Return default
    }
    return AvatarConfig.fromJson(response);
  }

  Future<void> updateAvatarConfig(AvatarConfig config) async {
    await _client.from('user_avatar_config').upsert(config.toJson());
  }

  // --- Game Match ---

  Stream<GameMatch> streamMatch(String matchId) {
    return _client
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((events) => GameMatch.fromJson(events.first));
  }

  Future<void> passPotato(String matchId, String nextUserId) async {
    // This could also trigger a Redis WebSocket backend event
    await _client.from('matches').update({
      'current_turn_user_id': nextUserId,
    }).eq('id', matchId);
  }
}
