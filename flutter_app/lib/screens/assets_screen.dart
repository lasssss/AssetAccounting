import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/asset.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  List<Asset> _assets = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String? _cardFilter;
  String? _statusFilter;
  bool _zeroResidual = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DatabaseHelper();
    _assets = await db.getAssets(
      search: _searchCtrl.text,
      card: _cardFilter,
      status: _statusFilter,
      zeroResidual: _zeroResidual ? true : null,
    );
    setState(() => _loading = false);
  }

  String _statusColor(String s) {
    return {'active': 'success', 'zip': 'primary', 'repair': 'warning',
      'disposed': 'secondary', 'for_disposal': 'danger'}[s] ?? 'default';
  }

  String _statusLabel(String s) {
    return {'active': 'В эксплуатации', 'zip': 'ЗИП', 'repair': 'В ремонте',
      'disposed': 'Списано', 'for_disposal': 'На списание',
      'transferred': 'Передано', 'unused': 'Не используется'}[s] ?? s;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'ru');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Поиск...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _load(); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => _load(),
          ),
        ),
        // Filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(child: Text('Всего: ${_assets.length}')),
              TextButton.icon(
                icon: const Icon(Icons.filter_alt),
                label: Text(_zeroResidual ? '0-я ст-ть' : 'Фильтр'),
                onPressed: () => setState(() { _zeroResidual = !_zeroResidual; _load(); }),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _assets.isEmpty
                  ? const Center(child: Text('Нет данных'))
                  : ListView.builder(
                      itemCount: _assets.length,
                      itemBuilder: (_, i) {
                        final a = _assets[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${a.inventoryNumber}  |  ${fmt.format(a.salvageValue)} ₽'),
                            trailing: Chip(label: Text(_statusLabel(a.status), style: const TextStyle(fontSize: 11))),
                            onTap: () {}, // navigate to detail
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}