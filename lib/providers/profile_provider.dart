import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_trip_planner/providers/chat_provider.dart';
import '../services/openai_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Token usage provider
final tokenUsageProvider = Provider<TokenUsage>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return TokenUsage(
    requestTokens: geminiService.requestTokens,
    responseTokens: geminiService.responseTokens,
    maxTokens: geminiService.maxTokens,
    totalCost: geminiService.totalCost,
  );
});

// User profile provider
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');

  return UserProfile(
    name: user.displayName ?? 'User',
    email: user.email ?? 'No email',
    initials: _getInitials(user.displayName ?? user.email ?? 'U'),
  );
});

String _getInitials(String name) {
  if (name.isEmpty) return 'U';

  final parts = name.split('@')[0].split(' ');
  if (parts.length > 1) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return name[0].toUpperCase();
}

// Model classes
class TokenUsage {
  final int requestTokens;
  final int responseTokens;
  final int maxTokens;
  final double totalCost;

  TokenUsage({
    required this.requestTokens,
    required this.responseTokens,
    required this.maxTokens,
    required this.totalCost,
  });
}

class UserProfile {
  final String name;
  final String email;
  final String initials;

  UserProfile({
    required this.name,
    required this.email,
    required this.initials,
  });
}
