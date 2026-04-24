import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../providers/quest_provider.dart';
import '../providers/academy_provider.dart';
import 'battle_screen.dart';
import 'inventory_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _gyroX = 0;
  double _gyroY = 0;
  StreamSubscription? _gyroSubscription;

  // Hero Avatar State
  int _currentHeroNodeIndex = 0;
  Offset _heroPosition = const Offset(0, 0);
  // ignore: unused_field
  bool _isHeroMoving = false;

  final List<Map<String, dynamic>> _nodes = [
    {'id': 'lesson1', 'x': 0.5, 'y': 1800.0, 'name': 'Variables'},
    {'id': 'lesson2', 'x': 0.3, 'y': 1600.0, 'name': 'Conditions'},
    {'id': 'lesson3', 'x': 0.7, 'y': 1400.0, 'name': 'Loops'},
    {'id': 'lesson4', 'x': 0.4, 'y': 1100.0, 'name': 'Lists'},
    {'id': 'lesson5', 'x': 0.6, 'y': 850.0, 'name': 'Functions'},
    {'id': 'lesson6', 'x': 0.5, 'y': 600.0, 'name': 'Classes'},
    {'id': 'lesson7', 'x': 0.4, 'y': 350.0, 'name': 'Modules'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _gyroX = (_gyroX + event.y * 2).clamp(-30, 30);
          _gyroY = (_gyroY + event.x * 2).clamp(-30, 30);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academy = context.read<AcademyProvider>();
      context.read<QuestProvider>().loadQuestState(
            academy.lessonStatus.entries
                .where((e) => e.value.isCompleted)
                .map((e) => e.key)
                .toList(),
          );
      
      // Initialize Hero Position
      final quest = context.read<QuestProvider>();
      final lastUnlockedId = quest.unlockedNodeIds.lastOrNull ?? 'lesson1';
      final index = _nodes.indexWhere((n) => n['id'] == lastUnlockedId);
      _currentHeroNodeIndex = index != -1 ? index : 0;
      
      final screenWidth = MediaQuery.of(context).size.width;
      _heroPosition = Offset(
        (_nodes[_currentHeroNodeIndex]['x'] as double) * screenWidth,
        (_nodes[_currentHeroNodeIndex]['y'] as double) + 50,
      );

      // Wait a bit then scroll to bottom
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('QUESTRIA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              );
            },
          )
        ],
      ),
      body: Consumer<QuestProvider>(
        builder: (context, quest, child) {
          return Stack(
            children: [
              // LAYER 0: Deep Space (Slowest)
              _buildParallaxLayer(0.1, _buildSpaceBackground(), gyroImpact: 0.5),
              
              // LAYER 1: Biome Ambience (Mid Speed)
              _buildParallaxLayer(0.3, _buildBiomeAmbience(), gyroImpact: 1.0),
              
              // LAYER 2: Main Content (1:1 Speed)
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Stack(
                  children: [
                    // Path & Nodes
                    Container(height: 2000), // Total map height
                    
                    // Biome Dividers
                    _buildBiomeSection("The Citadel", 0, 600, const [Color(0xFF0F172A), Color(0xFF1E293B)], Icons.auto_awesome),
                    _buildBiomeSection("The Labyrinth", 600, 1300, const [Color(0xFF1E1B4B), Color(0xFF312E81)], Icons.hub),
                    _buildBiomeSection("The Plains", 1300, 2000, const [Color(0xFF064E3B), Color(0xFF065F46)], Icons.landscape),

                    CustomPaint(
                      size: const Size(double.infinity, 2000),
                      painter: QuestPathPainter(
                        academyProvider: context.watch<AcademyProvider>(),
                        unlockedNodeIds: quest.unlockedNodeIds,
                        scrollOffset: _scrollOffset,
                      ),
                    ),
                    ..._buildNodes(context, quest),
                    _buildHeroAvatar(),
                  ],
                ),
              ),
              
              // LAYER 3: Foreground Fog (Fastest)
              IgnorePointer(
                child: _buildParallaxLayer(1.5, _buildForegroundEffects()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParallaxLayer(double speed, Widget child, {double gyroImpact = 0}) {
    return Positioned(
      top: -(_scrollOffset * speed) + (_gyroY * gyroImpact),
      left: (_gyroX * gyroImpact),
      right: -(_gyroX * gyroImpact),
      height: 3000,
      child: child,
    );
  }

  Widget _buildHeroAvatar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutBack,
      left: _heroPosition.dx - 30,
      top: _heroPosition.dy - 30,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF1E293B),
              child: Image.asset(
                'assets/icon/logo_foreground.png', // Using logo as requested
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "YOU",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _moveHeroToNode(int nodeIndex) {
    if (nodeIndex < 0 || nodeIndex >= _nodes.length) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _currentHeroNodeIndex = nodeIndex;
      _heroPosition = Offset(
        (_nodes[nodeIndex]['x'] as double) * screenWidth,
        (_nodes[nodeIndex]['y'] as double) + 50,
      );
      _isHeroMoving = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isHeroMoving = false);
      }
    });
  }

  Widget _buildSpaceBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF020617),
      ),
      child: CustomPaint(painter: _SpacePainter()),
    );
  }

  Widget _buildBiomeAmbience() {
    return Column(
      children: [
        const SizedBox(height: 100),
        _buildAmbienceItem(Icons.cloud, 0.2, Colors.white10),
        const SizedBox(height: 400),
        _buildAmbienceItem(Icons.settings, 0.3, Colors.blueAccent.withOpacity(0.05)),
        const SizedBox(height: 500),
        _buildAmbienceItem(Icons.wb_sunny, 0.1, Colors.yellowAccent.withOpacity(0.05)),
      ],
    );
  }

  Widget _buildAmbienceItem(IconData icon, double opacity, Color color) {
    return Center(child: Icon(icon, size: 200, color: color));
  }

  Widget _buildForegroundEffects() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.transparent,
            Colors.black.withOpacity(0.4),
          ],
        ),
      ),
    );
  }

  Widget _buildBiomeSection(String title, double top, double bottom, List<Color> colors, IconData icon) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: bottom - top,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: 50,
              child: Opacity(
                opacity: 0.05,
                child: Icon(icon, size: 200, color: Colors.white),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.2),
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNodes(BuildContext context, QuestProvider quest) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return _nodes.map((n) {
      final isUnlocked = quest.unlockedNodeIds.contains(n['id']);
      final academy = context.watch<AcademyProvider>();
      final isCompleted = academy.isLessonCompleted(n['id'] as String);
      final isBossNode = n['id'] == 'lesson3' || n['id'] == 'lesson5' || n['id'] == 'lesson7';

      return Positioned(
        left: (n['x'] as double) * screenWidth - 50,
        top: n['y'] as double,
        child: RepaintBoundary(
          child: QuestNodeWidget(
            id: n['id'] as String,
            name: n['name'] as String,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            isBoss: isBossNode,
            onTap: () async {
              if (isUnlocked) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BattleScreen(lessonId: n['id'] as String, isBoss: isBossNode)),
                );
                
                if (context.mounted) {
                  final academy = context.read<AcademyProvider>();
                  context.read<QuestProvider>().loadQuestState(
                    academy.lessonStatus.entries
                        .where((e) => e.value.isCompleted)
                        .map((e) => e.key)
                        .toList(),
                  );
                  
                  // Move Hero if new node unlocked
                  final newQuest = context.read<QuestProvider>();
                  final lastId = newQuest.unlockedNodeIds.lastOrNull;
                  final index = _nodes.indexWhere((n) => n['id'] == lastId);
                  if (index != -1 && index != _currentHeroNodeIndex) {
                    _moveHeroToNode(index);
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Node Encrypted. Complete previous quests!'), backgroundColor: Colors.orange),
                );
              }
            },
          ),
        ),
      );
    }).toList();
  }
}

class _SpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    for (var i = 0; i < 100; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QuestNodeWidget extends StatefulWidget {
  final String id;
  final String name;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isBoss;
  final VoidCallback onTap;

  const QuestNodeWidget({
    super.key,
    required this.id,
    required this.name,
    required this.isUnlocked,
    required this.isCompleted,
    this.isBoss = false,
    required this.onTap,
  });

  @override
  State<QuestNodeWidget> createState() => _QuestNodeWidgetState();
}

class _QuestNodeWidgetState extends State<QuestNodeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBoss = widget.isBoss;
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * (isBoss ? 0.15 : 0.1));
              return Transform.scale(
                scale: widget.isUnlocked && !widget.isCompleted ? scale : 1.0,
                child: Container(
                  width: isBoss ? 110 : 100,
                  height: isBoss ? 110 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (widget.isUnlocked)
                        BoxShadow(
                          color: widget.isCompleted 
                            ? Colors.amber.withOpacity(0.4) 
                            : (isBoss ? Colors.purpleAccent : Colors.blueAccent).withOpacity(0.4),
                          blurRadius: (isBoss ? 30 : 20) + (_pulseController.value * 10),
                          spreadRadius: isBoss ? 4 : 2,
                        ),
                    ],
                    border: Border.all(
                      color: widget.isUnlocked 
                        ? (widget.isCompleted 
                            ? Colors.amber 
                            : (isBoss ? Colors.purpleAccent : Colors.blueAccent)) 
                        : Colors.white10,
                      width: isBoss ? 6 : 4,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        widget.isUnlocked ? const Color(0xFF1E293B) : Colors.black,
                        widget.isUnlocked 
                          ? (widget.isCompleted 
                              ? Colors.amber.withOpacity(0.2) 
                              : (isBoss ? Colors.purpleAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2))) 
                          : Colors.black,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.isCompleted 
                        ? (isBoss ? Icons.workspace_premium : Icons.workspace_premium) 
                        : (widget.isUnlocked 
                            ? (isBoss ? Icons.all_inclusive : Icons.bolt) 
                            : Icons.lock_outline),
                      color: widget.isUnlocked 
                        ? (widget.isCompleted ? Colors.amber : (isBoss ? Colors.purpleAccent : Colors.blueAccent)) 
                        : Colors.white24,
                      size: isBoss ? 48 : 40,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isBoss ? Colors.purple.shade900 : Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isUnlocked 
                  ? (isBoss ? Colors.purpleAccent : Colors.blueAccent).withOpacity(0.3) 
                  : Colors.transparent
              ),
            ),
            child: Text(
              (isBoss ? "BOSS: " : "") + widget.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: widget.isUnlocked ? Colors.white : Colors.white24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestPathPainter extends CustomPainter {
  final AcademyProvider academyProvider;
  final List<String> unlockedNodeIds;
  final double scrollOffset;
  QuestPathPainter({
    required this.academyProvider,
    required this.unlockedNodeIds,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final screenWidth = size.width;

    _drawPath(canvas, Offset(screenWidth * 0.5, 1800), Offset(screenWidth * 0.3, 1600), paint, academyProvider.isLessonCompleted('lesson1'));
    _drawPath(canvas, Offset(screenWidth * 0.3, 1600), Offset(screenWidth * 0.7, 1400), paint, academyProvider.isLessonCompleted('lesson2'));
    _drawPath(canvas, Offset(screenWidth * 0.7, 1400), Offset(screenWidth * 0.4, 1100), paint, academyProvider.isLessonCompleted('lesson3'));
    _drawPath(canvas, Offset(screenWidth * 0.4, 1100), Offset(screenWidth * 0.6, 850), paint, academyProvider.isLessonCompleted('lesson4'));
    _drawPath(canvas, Offset(screenWidth * 0.6, 850), Offset(screenWidth * 0.5, 600), paint, academyProvider.isLessonCompleted('lesson5'));
    _drawPath(canvas, Offset(screenWidth * 0.5, 600), Offset(screenWidth * 0.4, 350), paint, academyProvider.isLessonCompleted('lesson6'));
  }

  void _drawPath(Canvas canvas, Offset start, Offset end, Paint paint, bool isSourceCompleted) {
    if (isSourceCompleted) {
      paint.color = Colors.blueAccent.withOpacity(0.8);
      paint.strokeWidth = 6;
      canvas.drawLine(start, end, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      paint.maskFilter = null;
    } else {
      paint.color = Colors.white.withOpacity(0.05);
      paint.strokeWidth = 2;
    }
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant QuestPathPainter oldDelegate) => 
    oldDelegate.scrollOffset != scrollOffset || 
    oldDelegate.academyProvider.lessonStatus.length != academyProvider.lessonStatus.length;
}
