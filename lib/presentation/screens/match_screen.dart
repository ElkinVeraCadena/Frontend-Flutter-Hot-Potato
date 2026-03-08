import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../providers/game_state.dart';
import '../theme/app_theme.dart';

class MatchScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isMatch = false;
  int _timeLeft = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).joinMatch(widget.matchId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkWord(String value, String targetWord) {
    setState(() {
      _isMatch = value.trim().toLowerCase() == targetWord.toLowerCase();
    });
  }

  void _passPotato() {
    if (_isMatch) {
      ref.read(gameStateProvider.notifier).passPotato("some_next_user_id");
      _textController.clear();
      setState(() {
        _isMatch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hot Potato Match'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: gameState.when(
        data: (match) {
          if (match == null) return const Center(child: Text('Joining match...'));
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: Text(
                    '$_timeLeft seconds left!',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.redAccent,
                      fontSize: 24,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Rive Animation Placeholder for Potato
                Expanded(
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        border: Border.all(color: AppTheme.primaryColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      // Ideally you load a Rive asset here:
                      // child: RiveAnimation.asset('assets/animations/potato.riv'),
                      child: const Center(
                        child: Text(
                          '🥔',
                          style: TextStyle(fontSize: 100),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Target Word
                Text(
                  'Target Word:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  match.targetWord,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // TextField
                TextField(
                  controller: _textController,
                  onChanged: (val) => _checkWord(val, match.targetWord),
                  decoration: const InputDecoration(
                    hintText: 'Type the target word...',
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Pass Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isMatch ? _passPotato : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMatch ? AppTheme.secondaryColor : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text('PASS POTATO!'),
                  ),
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
