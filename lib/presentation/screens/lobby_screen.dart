import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lobby_state.dart';
import '../providers/game_state.dart';
import '../providers/auth_state.dart';
import '../theme/app_theme.dart';
import 'match_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  late final TabController _tabController;
  int _rounds = 5;
  int _timePerTurn = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _createRoom() {
    ref.read(lobbyStateProvider.notifier).createRoom(
          totalRounds: _rounds,
          timePerTurn: _timePerTurn,
        );
  }

  void _joinRoom() {
    ref.read(lobbyStateProvider.notifier).joinRoom(_codeController.text.trim());
  }

  void _startMatch() {
    final lobby = ref.read(lobbyStateProvider.notifier);
    final room = lobby.startMatch();
    if (room == null) return;
    ref.read(gameStateProvider.notifier).startMatch(room);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MatchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lobby = ref.watch(lobbyStateProvider);
    final currentUserId = ref.watch(authStateProvider).value?.id ?? '';

    // Show error snackbar
    ref.listen<LobbyState>(lobbyStateProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        ref.read(lobbyStateProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: lobby.room == null
          ? _buildJoinOrCreate()
          : _buildWaitingRoom(lobby, currentUserId),
    );
  }

  // ---- No room yet: Create or Join ----
  Widget _buildJoinOrCreate() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('🥔 Hot Potato'),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB28B), Color(0xFFFF8C69)],
                ),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Create Room'),
              Tab(icon: Icon(Icons.login), text: 'Join Room'),
            ],
          ),
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [_buildCreateTab(), _buildJoinTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SectionTitle('Game Settings'),
          const SizedBox(height: 16),

          // Rounds picker
          _SettingCard(
            icon: Icons.flag_rounded,
            label: 'Rounds',
            child: Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  onTap: () => setState(() => _rounds = (_rounds - 1).clamp(2, 10)),
                ),
                const SizedBox(width: 12),
                Text('$_rounds',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                _StepButton(
                  icon: Icons.add,
                  onTap: () => setState(() => _rounds = (_rounds + 1).clamp(2, 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Time per turn picker
          _SettingCard(
            icon: Icons.timer_rounded,
            label: 'Seconds per turn',
            child: Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  onTap: () =>
                      setState(() => _timePerTurn = (_timePerTurn - 5).clamp(10, 60)),
                ),
                const SizedBox(width: 12),
                Text('${_timePerTurn}s',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                _StepButton(
                  icon: Icons.add,
                  onTap: () =>
                      setState(() => _timePerTurn = (_timePerTurn + 5).clamp(10, 60)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createRoom,
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('CREATE ROOM'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.group_add, size: 80, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Enter your friend\'s\nroom code',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: 'ABC123',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _joinRoom,
              icon: const Icon(Icons.login),
              label: const Text('JOIN ROOM'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Waiting room (room created, waiting for players to start) ----
  Widget _buildWaitingRoom(LobbyState lobby, String currentUserId) {
    final room = lobby.room!;
    final isHost = room.hostId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              ref.read(lobbyStateProvider.notifier).leaveRoom(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Room code banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB28B), Color(0xFFFF8C69)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Room Code',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    room.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: room.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text('Tap to copy',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Settings summary
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Chip('${room.totalRounds} rounds', Icons.flag_rounded),
                const SizedBox(width: 12),
                _Chip('${room.timePerTurn}s / turn', Icons.timer_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // Players list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Players (${room.participantIds.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: room.participantIds.length,
                itemBuilder: (ctx, i) {
                  final pid = room.participantIds[i];
                  final name = room.participantNames[pid] ?? 'Player';
                  final isCurrentUser = pid == currentUserId;
                  final isHost = pid == room.hostId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style:
                            const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                    title: Text(name),
                    subtitle: isCurrentUser ? const Text('(You)') : null,
                    trailing: isHost
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('HOST',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          )
                        : null,
                  );
                },
              ),
            ),

            // Start button (host only)
            if (isHost)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: room.participantIds.length >= 2 ? _startMatch : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: Text(room.participantIds.length < 2
                      ? 'Need at least 2 players'
                      : '🥔 START MATCH!'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppTheme.secondaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              )
            else
              const Text('Waiting for host to start...',
                  style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---- Small reusable widgets ----

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor));
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _SettingCard(
      {required this.icon, required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor))),
          child,
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryColor),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip(this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
