import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:confetti/confetti.dart';
import '../providers/quest_provider.dart';
import '../providers/academy_provider.dart';
import '../services/sensory_feedback_service.dart';

class BattleScreen extends StatefulWidget {
  final String lessonId;
  final bool isBoss;
  const BattleScreen({super.key, required this.lessonId, this.isBoss = false});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  int _monsterHP = 100;
  int _maxMonsterHP = 100;
  int _userHearts = 3;
  int _maxHearts = 3;
  int _attackDamage = 40;
  bool _statsLoaded = false;
  String? _selectedTask;
  String? _correctAnswer;
  List<String> _options = [];
  bool _isGameOver = false;
  
  // Animation State
  late ConfettiController _confettiController;
  bool _isShaking = false;
  bool _isMonsterHit = false;
  List<Map<String, dynamic>> _damageTexts = [];
  final _feedback = SensoryFeedbackService();

  final Map<String, dynamic> _challenges = {
    'lesson1': {
      'task': 'print("Hello" _ "World")',
      'options': ['+', '*', '/', '-'],
      'correct': '+',
      'reward': 'P-String Sword'
    },
    'lesson2': {
      'task': 'if x _ 10:',
      'options': ['==', '=', 'is', 'in'],
      'correct': '==',
      'reward': 'Logic Shield'
    },
    'lesson3': {
      'task': 'for i _ range(5):',
      'options': ['in', 'is', 'for', 'of'],
      'correct': 'in',
      'reward': 'Iteration Boots'
    },
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statsLoaded) {
      final quest = context.read<QuestProvider>();
      
      // Apply shield defense power (bonus hearts)
      if (quest.equippedShield != null) {
        int bonus = (quest.equippedShield!['defense_power'] as int?) ?? 0;
        // e.g. 1 defense power = 1 extra heart
        _maxHearts += bonus;
        _userHearts = _maxHearts;
      }
      
      // Apply weapon attack power
      if (quest.equippedWeapon != null) {
        int bonus = (quest.equippedWeapon!['attack_power'] as int?) ?? 0;
        _attackDamage += bonus;
      }
      
      _statsLoaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isBoss) {
      _monsterHP = 200;
      _maxMonsterHP = 200;
    }
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadNextChallenge();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _loadNextChallenge() {
    final challenge = _challenges[widget.lessonId] ?? _challenges['lesson1'];
    setState(() {
      _selectedTask = challenge['task'];
      _options = List<String>.from(challenge['options']);
      _correctAnswer = challenge['correct'];
    });
  }

  int _pendingXP = 0;

  void _handleAttack(String option) {
    if (option == _correctAnswer) {
      _triggerHitEffect(_attackDamage.toDouble());
      _feedback.playSlashSfx();
      _feedback.triggerHaptic();
      setState(() {
        _monsterHP -= _attackDamage;
        _pendingXP += (widget.isBoss ? 150 : 50);
        if (_monsterHP <= 0) {
          _monsterHP = 0;
          _isGameOver = true;
          _onVictory();
        }
      });
    } else {
      _triggerShakeEffect();
      _feedback.playThudSfx();
      _feedback.triggerHeavyHaptic();
      setState(() {
        _userHearts -= 1;
        if (_userHearts <= 0) {
          _isGameOver = true;
          _onDefeat();
        }
      });
    }
  }

  void _triggerHitEffect(int damage) {
    setState(() {
      _isMonsterHit = true;
      _damageTexts.add({
        'text': '-$damage HP',
        'color': Colors.redAccent,
        'offset': const Offset(0, -20),
        'id': DateTime.now().millisecondsSinceEpoch,
      });
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isMonsterHit = false);
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_damageTexts.isNotEmpty) _damageTexts.removeAt(0);
        });
      }
    });
  }

  void _triggerShakeEffect() {
    setState(() => _isShaking = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isShaking = false);
    });
  }

  void _onVictory() async {
    final challenge = _challenges[widget.lessonId] ?? _challenges['lesson1'];
    final quest = context.read<QuestProvider>();
    final academy = context.read<AcademyProvider>();

    // Determine attack power based on lesson/challenge type
    int earnedAttack = 20;
    int earnedDefense = 0;
    String category = 'Weapon';

    if (challenge['reward'].toString().contains('Shield')) {
      category = 'Shield';
      earnedDefense = 1;
      earnedAttack = 0;
    } else if (challenge['reward'].toString().contains('Boots')) {
      category = 'Accessory';
    }

    await quest.earnItem(
      itemId: widget.lessonId,
      itemName: challenge['reward'],
      category: category,
      attackPower: earnedAttack,
      defensePower: earnedDefense,
    );
    
    // Bosses drop Gems
    int gemsEarned = 0;
    if (widget.isBoss) {
      gemsEarned = 50;
      await quest.addGems(gemsEarned);
    }
    
    // Capture old level before adding XP
    int oldLevel = academy.currentLevel;

    // Push batched XP to Academy and Firestore
    await academy.addXP(_pendingXP);
    
    // MARK LESSON AS COMPLETE TO UNLOCK NEXT QUEST NODE
    await academy.completeLesson(widget.lessonId, 1.0);

    if (mounted) {
      _confettiController.play();
      _feedback.triggerSuccessHaptic();

      String rewardMessage = 'You defeated the Bug and earned the ${challenge['reward']}!';
      if (gemsEarned > 0) {
        rewardMessage += '\n+$gemsEarned Gems!';
      }

      if (academy.currentLevel > oldLevel) {
        _showResultDialog('LEVEL UP!', 'You reached Level ${academy.currentLevel}! $rewardMessage');
      } else {
        _showResultDialog('VICTORY!', rewardMessage);
      }
    }
  }


  void _onDefeat() {
    _showResultDialog('DEFEAT', 'The Bug overwhelmed you. Try again later.');
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit battle
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: Text(
          widget.isBoss ? 'BOSS BATTLE: ${widget.lessonId.toUpperCase()}' : 'BATTLE: ${widget.lessonId.toUpperCase()}', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBattleUI(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleUI() {
    return Animate(
      target: _isShaking ? 1 : 0,
      effects: [ShakeEffect(duration: 500.ms, hz: 10, offset: const Offset(10, 0))],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Monster Section
            _buildMonsterSection(),
            const Spacer(),
            // Challenge Area
            if (!_isGameOver) _buildChallengeArea(),
            const Spacer(),
            // User Section (HUD)
            _buildUserHUD(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonsterSection() {
    return Column(
      children: [
        Text(
          widget.isBoss ? 'INFINITE LOOP DRAGON' : 'THE SYNTAX BUG',
          style: TextStyle(
            color: widget.isBoss ? Colors.purpleAccent.withOpacity(0.8) : Colors.redAccent.withOpacity(0.8),
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          animation: true,
          lineHeight: 12.0,
          animationDuration: 500,
          percent: _monsterHP / _maxMonsterHP,
          barRadius: const Radius.circular(10),
          progressColor: Colors.redAccent,
          backgroundColor: Colors.white10,
        ),
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            // Breathing animation
            Animate(
              effects: [
                ScaleEffect(
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                ),
              ],
              onInit: (controller) => controller.repeat(reverse: true),
              child: Animate(
                target: _isMonsterHit ? 1 : 0,
                effects: [
                  TintEffect(color: (widget.isBoss ? Colors.purple : Colors.red).withOpacity(0.5), duration: 200.ms),
                  ShakeEffect(duration: 200.ms),
                ],
                child: Icon(
                  widget.isBoss ? Icons.all_inclusive : Icons.bug_report, 
                  size: 180, 
                  color: widget.isBoss ? Colors.purpleAccent : Colors.greenAccent
                ),
              ),
            ),
            // Floating damage numbers
            ..._damageTexts.map((d) => Animate(
              key: ValueKey(d['id']),
              effects: [
                MoveEffect(begin: const Offset(0, 0), end: const Offset(0, -100), duration: 1.seconds),
                FadeEffect(duration: 1.seconds),
              ],
              child: Text(
                d['text'],
                style: TextStyle(color: d['color'], fontSize: 32, fontWeight: FontWeight.bold),
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildUserHUD() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PLAYER', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(_maxHearts, (i) => Icon(
                i < _userHearts ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent,
                size: 20,
              ).animate(target: i < _userHearts ? 0 : 1).shake()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          animation: true,
          lineHeight: 12.0,
          animationDuration: 500,
          percent: _userHearts / _maxHearts,
          barRadius: const Radius.circular(10),
          progressColor: Colors.blueAccent,
          backgroundColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _buildChallengeArea() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
          ),
          child: Text(
            _selectedTask ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontFamily: 'monospace',
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _options.map((opt) => _buildAttackButton(opt)).toList(),
        ),
      ],
    );
  }

  Widget _buildAttackButton(String label) {
    return _AttackButton(
      label: label,
      onTap: () => _handleAttack(label),
    );
  }
}

class _AttackButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AttackButton({required this.label, required this.onTap});

  @override
  State<_AttackButton> createState() => _AttackButtonState();
}

class _AttackButtonState extends State<_AttackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Animate(
        target: _isPressed ? 1 : 0,
        effects: [ScaleEffect(begin: const Offset(1, 1), end: const Offset(0.9, 0.9), duration: 100.ms)],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
