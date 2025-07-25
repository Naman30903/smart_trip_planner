import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_trip_planner/providers/database_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenUsageAsync = ref.watch(tokenUsageProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(tokenUsageProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9F7F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // User profile card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // User info
                      userProfileAsync.when(
                        data: (profile) => Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFF00704A),
                              child: Text(
                                profile.initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<String?>(
                              future: ref
                                  .read(databaseServiceProvider)
                                  .getUserName(),
                              builder: (context, snapshot) {
                                final userName = snapshot.data ?? "User";
                                return Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Color(0xFF00704A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                );
                              },
                            ),
                            Text(
                              profile.email,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text("Error loading profile"),
                      ),
                      const Divider(height: 32),

                      // Request tokens
                      tokenUsageAsync.when(
                        data: (tokenUsage) {
                          return Column(
                            children: [
                              _buildTokenRow(
                                'Request Tokens',
                                tokenUsage.requestTokens,
                                tokenUsage.maxTokens,
                                const Color(0xFF00704A),
                              ),
                              const SizedBox(height: 24),
                              _buildTokenRow(
                                'Response Tokens',
                                tokenUsage.responseTokens,
                                tokenUsage.maxTokens,
                                Colors.redAccent,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Cost',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "\$${tokenUsage.totalCost.toStringAsFixed(6)} USD",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00704A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            Text('Error loading token usage: $error'),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Logout button
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      // AuthWrapper will handle navigation
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error logging out: $e")),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenRow(
    String label,
    int current,
    int max,
    Color progressColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "$current/$max",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: current / max,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
