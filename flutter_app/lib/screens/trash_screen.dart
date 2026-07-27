import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/asset.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Asset> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _items = await DatabaseHelper().getAssets(deleted: true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _items.isEmpty
        ? const Center(child: Text('Корзина пуста'))
        : ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final a = _items[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: ListTile(
                  title: Text(a.name),
                  subtitle: Text(a.deletedReason ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () async {
                          await DatabaseHelper().restoreAsset(a.id!);
                          _load();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Удалить навсегда?'),
                              content: Text('${a.name} — это необратимо'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await DatabaseHelper().deleteAssetPermanently(a.id!);
                            _load();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}