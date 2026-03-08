import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
            },
            tooltip: 'Log out',
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          // XP logic (e.g. 100 XP per level)
          final xpForNextLevel = user.level * 100;
          final currentLevelXp = user.totalXP % 100;
          final progress = currentLevelXp / 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Header
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                     user.name.substring(0, 1).toUpperCase(),
                     style: const TextStyle(fontSize: 40, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                ),
                Text(
                  '@${user.username}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Level & XP Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Level ${user.level}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('${user.totalXP} TOTAL XP', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$currentLevelXp / 100 XP to Level ${user.level + 1}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Language Stats
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Language Stats',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 16),
                
                ...user.languageStats.entries.map((stat) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.backgroundColor,
                        child: Icon(Icons.translate, color: AppTheme.secondaryColor),
                      ),
                      title: Text(stat.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                           color: AppTheme.primaryColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Level ${stat.value}',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                if (user.languageStats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No language stats available yet. Play a match!'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
