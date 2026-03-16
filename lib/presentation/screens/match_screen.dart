import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_state.dart';
import '../providers/auth_state.dart';
import '../providers/lobby_state.dart';
import '../theme/app_theme.dart';
import 'game_result_screen.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _potatoShakeController;
  late final Animation<double> _potatoShake;

  @override
  void initState() {
    super.initState();
    _potatoShakeController = AnimationController(
        duration: const Duration(milliseconds: 60), vsync: this);
    _potatoShake = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _potatoShakeController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _potatoShakeController.dispose();
    super.dispose();
  }

  void _tryPassPotato(String userId, GameState game) {
    final input = _textController.text.trim().toLowerCase();
    final target = game.currentChallenge?.word.toLowerCase() ?? '';
    if (input == target) {
      ref.read(gameStateProvider.notifier).passPotato(userId);
      _textController.clear();
      // Shake potato on pass
      _potatoShakeController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _potatoShakeController.stop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameStateProvider);
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserId = currentUser?.id ?? '';

    // React to phase changes
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (next.phase == GamePhase.roundEnd) {
        _showRoundEndDialog(next, currentUserId);
      } else if (next.phase == GamePhase.gameOver) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GameResultScreen()),
        );
      }
    });

    if (game.room == null || game.phase == GamePhase.idle) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final room = game.room!;
    final challenge = game.currentChallenge;
    final myTurn = game.isMyTurn(currentUserId);
    final timeLeft = game.timeLeft;
    final totalTime = room.timePerTurn;

    // Timer color: green → yellow → red
    final timerRatio = timeLeft / totalTime;
    final timerColor = timerRatio > 0.6
        ? const Color(0xFF66BB6A)
        : timerRatio > 0.3
            ? const Color(0xFFFFCA28)
            : AppTheme.errorColor;

    final holderName = game.nameOf(room.currentTurnUserId);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F0), Color(0xFFFFFDF7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ---- Header ----
              _buildHeader(context, room, game),
              const SizedBox(height: 8),

              // ---- Timer ring ----
              _buildTimerRing(timeLeft, totalTime, timerColor),
              const SizedBox(height: 12),

              // ---- Turn indicator ----
              _buildTurnIndicator(myTurn, holderName),
              const SizedBox(height: 16),

              // ---- Animated Potato ----
              _buildPotato(myTurn),
              const SizedBox(height: 16),

              // ---- Word challenge ----
              if (challenge != null)
                _buildChallenge(context, challenge, myTurn),
              const Spacer(),

              // ---- Input + button ----
              if (myTurn && challenge != null)
                _buildInputArea(challenge, currentUserId, game),
              if (!myTurn)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '⏳ Waiting for $holderName to pass the potato...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondaryColor, fontSize: 16),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Widgets ----

  Widget _buildHeader(BuildContext context, room, GameState game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB28B), Color(0xFFFF8C69)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Round ${room.currentRound} / ${room.totalRounds}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const Text('🥔 Hot Potato',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Row(
            children: room.participantIds.map((pid) {
              final isElim = room.isEliminated(pid);
              final isTurn = room.currentTurnUserId == pid;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isElim
                          ? Colors.grey.shade400
                          : (isTurn
                              ? Colors.white
                              : Colors.white.withOpacity(0.5)),
                      child: Text(
                        (room.participantNames[pid] ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isElim
                              ? Colors.grey
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    if (isTurn && !isElim)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFCA28),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🥔',
                                style: TextStyle(fontSize: 6)),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRing(int timeLeft, int totalTime, Color timerColor) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: timeLeft / totalTime,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(timerColor),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$timeLeft',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: timerColor),
              ),
              const Text('sec',
                  style:
                      TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(bool myTurn, String holderName) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: myTurn
            ? AppTheme.errorColor.withOpacity(0.12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: myTurn ? AppTheme.errorColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        myTurn ? '🔥 YOU HAVE THE POTATO!' : '🙂 $holderName has the potato',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: myTurn ? AppTheme.errorColor : AppTheme.textSecondaryColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPotato(bool myTurn) {
    return AnimatedBuilder(
      animation: _potatoShake,
      builder: (_, child) => Transform.translate(
        offset: Offset(_potatoShake.value, 0),
        child: child,
      ),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: myTurn
              ? AppTheme.primaryColor.withOpacity(0.15)
              : Colors.grey.shade100,
          border: Border.all(
            color: myTurn ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 4,
          ),
          boxShadow: myTurn
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            myTurn ? '🥔🔥' : '🥔',
            style: const TextStyle(fontSize: 72),
          ),
        ),
      ),
    );
  }

  Widget _buildChallenge(BuildContext context, challenge, bool myTurn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            myTurn ? 'Type this word:' : 'Word to type:',
            style: const TextStyle(
                color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.word,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: myTurn ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '💡 ${challenge.hint}',
            style: const TextStyle(
                color: AppTheme.textSecondaryColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(challenge, String userId, GameState game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Letter-by-letter feedback
          _LetterFeedback(
            typed: _textController.text,
            target: challenge.word,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _tryPassPotato(userId, game),
                  decoration: const InputDecoration(
                    hintText: 'Type the word...',
                    prefixIcon: Icon(Icons.keyboard),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _textController.text.trim().toLowerCase() ==
                          challenge.word.toLowerCase()
                      ? () => _tryPassPotato(userId, game)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('PASS\n🥔', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoundEndDialog(GameState game, String currentUserId) {
    final eliminated = game.eliminatedThisRound;
    final name = eliminated != null ? game.nameOf(eliminated) : 'Someone';
    final isMe = eliminated == currentUserId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔥 Potato Exploded!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💥', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 8),
            Text(
              isMe ? '😱 You got burned!' : '🎉 $name got burned!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isMe
                  ? 'Better luck next time! You\'re out this round.'
                  : '$name is eliminated from this round!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(gameStateProvider.notifier).continueAfterRound();
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Letter-by-letter feedback widget ----

class _LetterFeedback extends StatelessWidget {
  final String typed;
  final String target;
  const _LetterFeedback({required this.typed, required this.target});

  @override
  Widget build(BuildContext context) {
    if (typed.isEmpty) return const SizedBox.shrink();
    return Row(
      children: List.generate(target.length, (i) {
        final hasTyped = i < typed.length;
        final correct =
            hasTyped && typed[i].toLowerCase() == target[i].toLowerCase();
        return Container(
          width: 26,
          height: 30,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: !hasTyped
                ? Colors.grey.shade200
                : (correct
                    ? const Color(0xFF66BB6A).withOpacity(0.2)
                    : AppTheme.errorColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: !hasTyped
                  ? Colors.grey.shade300
                  : (correct
                      ? const Color(0xFF66BB6A)
                      : AppTheme.errorColor),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              target[i].toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: !hasTyped
                    ? Colors.grey.shade400
                    : (correct
                        ? const Color(0xFF388E3C)
                        : AppTheme.errorColor),
              ),
            ),
          ),
        );
      }),
    );
  }
}
