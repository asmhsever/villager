// 📁 lib/views/juristic/house_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_villager_screen.dart';
import 'edit_house_screen.dart';
import 'villager_detail_screen.dart';

class HouseDetailScreen extends StatefulWidget {
  final int houseId;
  const HouseDetailScreen({super.key, required this.houseId});

  @override
  State<HouseDetailScreen> createState() => _HouseDetailScreenState();
}

class _HouseDetailScreenState extends State<HouseDetailScreen> {
  Map<String, dynamic>? house;
  List<Map<String, dynamic>> villagers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    try {
      final h = await client
          .from('house')
          .select()
          .eq('house_id', widget.houseId)
          .maybeSingle();

      final v = await client
          .from('villager')
          .select()
          .eq('house_id', widget.houseId);

      setState(() {
        house = h;
        villagers = List<Map<String, dynamic>>.from(v);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load house details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteHouse() async {
    await Supabase.instance.client.from('house').delete().eq('house_id', widget.houseId);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteVillager(int id) async {
    await Supabase.instance.client.from('villager').delete().eq('villager_id', id);
    _loadData();
  }

  void _editVillager(Map<String, dynamic> villager) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VillagerDetailScreen(villager: villager),
      ),
    ).then((_) => _loadData());
  }

  void _addVillager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditVillagerScreen(houseId: widget.houseId),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดบ้าน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditHouseScreen(house: house!),
              ),
            ).then((_) => _loadData()),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteHouse,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVillager,
        child: const Icon(Icons.person_add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏠 เจ้าของบ้าน: ${house?['username'] ?? '-'}'),
            Text('📏 ขนาด: ${house?['size'] ?? '-'}'),
            Text('🏡 หมู่บ้าน: ${house?['village_id'] ?? '-'}'),
            const Divider(height: 30),
            const Text('ลูกบ้านในบ้านนี้:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...villagers.map((v) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('${v['first_name']} ${v['last_name']}'),
              subtitle: Text('เบอร์: ${v['phone']}'),
              onTap: () => _editVillager(v),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteVillager(v['villager_id']),
              ),
            ))
          ],
        ),
      ),
    );
  }
}
