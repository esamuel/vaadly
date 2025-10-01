import 'package:flutter/material.dart';
import '../../core/models/building.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import '../../services/firebase_building_service.dart';
import '../../core/widgets/auth_wrapper.dart';

class BuildingSelectorPage extends StatefulWidget {
  const BuildingSelectorPage({super.key});

  @override
  State<BuildingSelectorPage> createState() => _BuildingSelectorPageState();
}

class _BuildingSelectorPageState extends State<BuildingSelectorPage> {
  bool _loading = true;
  List<Building> _buildings = [];

  @override
  void initState() {
    super.initState();
    _loadAccessibleBuildings();
  }

  Future<void> _loadAccessibleBuildings() async {
    setState(() => _loading = true);
    final user = AuthService.currentUser!;
    final access = user.buildingAccess;
    final list = <Building>[];
    try {
      if (user.isAppOwner || access.containsKey('all')) {
        list.addAll(await FirebaseBuildingService.getAllBuildings());
      } else {
        for (final key in access.keys) {
          final byId = await FirebaseBuildingService.getBuildingById(key);
          if (byId != null) {
            list.add(byId);
            continue;
          }
          final byCode = await FirebaseBuildingService.getBuildingByCode(key);
          if (byCode != null) list.add(byCode);
        }
      }
    } catch (e) {
      // ignore and show whatever collected
    } finally {
      setState(() {
        _buildings = list;
        _loading = false;
      });
    }
  }

  Future<void> _select(Building b) async {
    try {
      await BuildingContextService.setBuildingContext(b.id);
    } catch (_) {
      try {
        await BuildingContextService.setBuildingContextByCode(b.buildingCode);
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthWrapper(buildingCode: b.buildingCode)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('בחר בניין'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildings.isEmpty
              ? const Center(child: Text('לא נמצאו בניינים זמינים'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _buildings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = _buildings[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.business, color: Colors.indigo),
                        title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${b.address}, ${b.city}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _select(b),
                      ),
                    );
                  },
                ),
    );
  }
}

