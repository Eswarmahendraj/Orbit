import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/aura_theme.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Sample data — replace with Firestore streams
  final _dms = [
    _DMData('Silver Tide', '🌿', AuraColors.moodCalm, 'energy'),
    _DMData('Amber Wisp', '🌸', AuraColors.moodHappy, 'calm'),
    _DMData('Velvet Storm', '🌟', AuraColors.moodEnergy, 'love'),
    _DMData('Cosmic Shore', '🔥', AuraColors.moodFocus, 'focus'),
    _DMData('Pale Ember', '💫', AuraColors.moodSad, 'sad'),
  ];

  final _circles = [
    _CircleData('Late Night Crew', ['Silver', 'Amber', 'Vel'], 3),
    _CircleData('Study Buddies', ['Cosmic', 'Pale', 'Gold'], 3),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Messages'),
      bottom: TabBar(
        controller: _tab,
        indicatorColor: AuraColors.accent,
        labelColor: AuraColors.accent,
        unselectedLabelColor: AuraColors.textSecondary,
        tabs: const [
          Tab(text: 'Direct'),
          Tab(text: 'Circle Threads'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tab,
      children: [
        // Direct messages
        ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _dms.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _DMTile(
            data: _dms[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(
                peerAuraName: _dms[i].name,
                peerId: 'peer_$i',
                peerColor: _dms[i].color,
                tenureEmoji: _dms[i].emoji,
              ),
            )),
          ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05),
        ),

        // Circle threads
        ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _circles.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Circle Thread'),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuraColors.accent,
                    side: const BorderSide(color: AuraColors.accent),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              );
            }
            return _CircleTile(data: _circles[i - 1])
                .animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05);
          },
        ),
      ],
    ),
  );
}

class _DMData {
  final String name, emoji, mood;
  final Color color;
  const _DMData(this.name, this.emoji, this.color, this.mood);
}

class _CircleData {
  final String name;
  final List<String> previewNames;
  final int memberCount;
  const _CircleData(this.name, this.previewNames, this.memberCount);
}

class _DMTile extends StatelessWidget {
  final _DMData data;
  final VoidCallback onTap;
  const _DMTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    onTap: onTap,
    leading: Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: data.color.withOpacity(0.2),
          child: Text(data.name[0],
              style: TextStyle(color: data.color,
                  fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AuraColors.background,
              shape: BoxShape.circle,
            ),
            child: Text(data.emoji, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    ),
    title: Text(data.name,
        style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(data.mood,
              style: TextStyle(color: data.color, fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ),
    trailing: const Icon(Icons.chevron_right,
        color: AuraColors.textSecondary, size: 18),
  );
}

class _CircleTile extends StatelessWidget {
  final _CircleData data;
  const _CircleTile({required this.data});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    onTap: () {},
    leading: SizedBox(
      width: 52, height: 52,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AuraColors.accent.withOpacity(0.15),
            child: const Icon(Icons.group_outlined,
                color: AuraColors.accent, size: 22),
          ),
        ],
      ),
    ),
    title: Text(data.name,
        style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text('${data.memberCount} members',
        style: const TextStyle(
            color: AuraColors.textSecondary, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right,
        color: AuraColors.textSecondary, size: 18),
  );
}
