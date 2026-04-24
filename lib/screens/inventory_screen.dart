import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Vault of Variables', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Consumer<QuestProvider>(
                builder: (context, quest, child) {
                  return Row(
                    children: [
                      const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${quest.gems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'GEAR', icon: Icon(Icons.shield)),
            Tab(text: 'SHOP', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGearTab(),
          _buildShopTab(),
        ],
      ),
    );
  }

  Widget _buildGearTab() {
    return Consumer<QuestProvider>(
      builder: (context, quest, child) {
        final inventory = quest.gameInventory;
        if (inventory.isEmpty) {
          return const Center(
            child: Text(
              "Your vault is empty.\nDefeat bugs to earn loot!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final item = inventory[index];
            final isEquipped = item['is_equipped'] == 1;

            return Card(
              color: const Color(0xFF2D2D44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isEquipped ? Colors.cyanAccent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['category'] == 'Weapon' ? Icons.colorize : Icons.security,
                    size: 48,
                    color: isEquipped ? Colors.cyanAccent : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['item_name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item['attack_power'] > 0)
                    Text('ATK +${item['attack_power']}', style: const TextStyle(color: Colors.redAccent)),
                  if (item['defense_power'] > 0)
                    Text('DEF +${item['defense_power']}', style: const TextStyle(color: Colors.blueAccent)),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEquipped ? Colors.transparent : Colors.cyanAccent.withOpacity(0.2),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isEquipped
                          ? null
                          : () {
                              quest.equipItem(item['item_id'], item['category']);
                            },
                      child: Text(
                        isEquipped ? 'EQUIPPED' : 'EQUIP',
                        style: TextStyle(
                          color: isEquipped ? Colors.grey : Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopTab() {
    return Consumer<QuestProvider>(
      builder: (context, quest, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildShopItem(
              icon: Icons.favorite,
              name: 'Health Potion',
              description: 'Restores 1 Heart in battle.',
              price: 100,
              iconColor: Colors.pinkAccent,
              onBuy: () {
                if (quest.gems >= 100) {
                  quest.spendGems(100);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchased Health Potion!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough gems!')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildShopItem(
              icon: Icons.person_outline,
              name: 'Neon Knight Skin',
              description: 'A glowing cyan avatar skin.',
              price: 500,
              iconColor: Colors.cyanAccent,
              onBuy: () {
                if (quest.gems >= 500) {
                  quest.spendGems(500);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchased Neon Knight Skin!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough gems!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildShopItem({
    required IconData icon,
    required String name,
    required String description,
    required int price,
    required Color iconColor,
    required VoidCallback onBuy,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$price',
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onBuy,
          child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
