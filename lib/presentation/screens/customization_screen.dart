import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../../domain/models/avatar_config.dart';
import '../providers/avatar_state.dart';
import '../theme/app_theme.dart';

class CustomizationScreen extends ConsumerStatefulWidget {
  const CustomizationScreen({super.key});

  @override
  ConsumerState<CustomizationScreen> createState() =>
      _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen> {
  File? _riveFile;
  RiveWidgetController? _controller;
  NumberInput? _hairInput;
  NumberInput? _beardInput;
  NumberInput? _clothesInput;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    _riveFile = await File.asset(
      'assets/rive/potato_character.riv',
      riveFactory: Factory.rive,
    );
    _controller = RiveWidgetController(_riveFile!);
    _hairInput = _controller?.stateMachine.number('Hair');
    _beardInput = _controller?.stateMachine.number('Beard');
    _clothesInput = _controller?.stateMachine.number('Clothes');
    _updateRiveInputs();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateRiveInputs() {
    final avatarState = ref.read(avatarStateProvider);
    avatarState.whenData((config) {
      if (_hairInput != null) {
        _hairInput!.value = _mapStringToDouble(config.hair, [
          'none',
          'spiky',
          'curly',
          'long',
        ]);
      }
      if (_beardInput != null) {
        _beardInput!.value = _mapStringToDouble(config.beard, [
          'none',
          'goatee',
          'full',
          'mustache',
        ]);
      }
      if (_clothesInput != null) {
        _clothesInput!.value = _mapStringToDouble(config.clothes, [
          'basic_shirt',
          'hoodie',
          'suit',
          'jacket',
        ]);
      }
    });
  }

  double _mapStringToDouble(String value, List<String> options) {
    final index = options.indexOf(value);
    return index >= 0 ? index.toDouble() : 0.0;
  }

  @override
  void dispose() {
    _hairInput?.dispose();
    _beardInput?.dispose();
    _clothesInput?.dispose();
    _controller?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(avatarStateProvider);

    // Listen to changes to update Rive inputs
    ref.listen<AsyncValue<AvatarConfig>>(avatarStateProvider, (previous, next) {
      next.whenData((_) {
        _updateRiveInputs();
      });
    });

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
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _riveFile == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.face,
                                        size: 80,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Awaiting Rive Asset',
                                        style: TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : RiveWidget(
                                    controller: _controller!,
                                    fit: Fit.cover,
                                  ),
                            // Optional overlay to show config strictly for testing if river asset fails
                            // Positioned(
                            //   bottom: 10,
                            //   child: Text('Hair: ${config.hair} | Beard: ${config.beard}', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            // ),
                          ],
                        ),
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Customize',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      _buildCategory(
                        'Hair',
                        config.hair,
                        ['none', 'spiky', 'curly', 'long'],
                        (val) => ref
                            .read(avatarStateProvider.notifier)
                            .updateConfig(hair: val),
                      ),
                      _buildCategory(
                        'Beard',
                        config.beard,
                        ['none', 'goatee', 'full', 'mustache'],
                        (val) => ref
                            .read(avatarStateProvider.notifier)
                            .updateConfig(beard: val),
                      ),
                      _buildCategory(
                        'Clothes',
                        config.clothes,
                        ['basic_shirt', 'hoodie', 'suit', 'jacket'],
                        (val) => ref
                            .read(avatarStateProvider.notifier)
                            .updateConfig(clothes: val),
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
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
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.15)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      option.replaceAll('_', '\n'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
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
