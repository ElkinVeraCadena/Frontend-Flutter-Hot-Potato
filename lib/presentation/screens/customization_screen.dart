import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:rive/rive.dart';
import '../providers/avatar_state.dart';
import '../theme/app_theme.dart';

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarState = ref.watch(avatarStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: avatarState.when(
        data: (config) {
          return Column(
            children: [
              // Rive Preview Area
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  color: AppTheme.backgroundColor,
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      // child: const RiveAnimation.asset(
                      //   'assets/animations/avatar.riv',
                      //   // This is where you would hook up StateMachineControllers to update the Rive inputs
                      //   // using the config.toMap()
                      // ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.face, size: 80, color: AppTheme.primaryColor),
                          const SizedBox(height: 10),
                          Text('Hair: ${config.hair}'),
                          Text('Beard: ${config.beard}'),
                          Text('Clothes: ${config.clothes}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Customization Controls
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Customize',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildCategory(
                        context,
                        ref,
                        'Hair',
                        config.hair,
                        ['none', 'spiky', 'curly', 'long'],
                        (val) => ref.read(avatarStateProvider.notifier).updateConfig(hair: val),
                      ),
                      _buildCategory(
                        context,
                        ref,
                        'Beard',
                        config.beard,
                        ['none', 'goatee', 'full', 'mustache'],
                        (val) => ref.read(avatarStateProvider.notifier).updateConfig(beard: val),
                      ),
                      _buildCategory(
                        context,
                        ref,
                        'Clothes',
                        config.clothes,
                        ['basic_shirt', 'hoodie', 'suit', 'jacket'],
                        (val) => ref.read(avatarStateProvider.notifier).updateConfig(clothes: val),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    WidgetRef ref,
    String title,
    String currentValue,
    List<String> options,
    Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == currentValue;

              return GestureDetector(
                onTap: () => onSelect(option),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
