import 'package:flutter/material.dart';

import '../../../theme/potatuhs.dart';
import '../../../vipotato.dart';
import 'vipotato_avatar.dart';

/// Opens the VIPotato builder. Returns the saved [VIPotatoConfig] when the user
/// saves & equips, or null if they back out.
Future<VIPotatoConfig?> openVIPotatoBuilder(
  BuildContext context, {
  VIPotatoConfig? initial,
}) {
  return Navigator.of(context).push<VIPotatoConfig>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => VIPotatoBuilderPage(initial: initial),
    ),
  );
}

class VIPotatoBuilderPage extends StatefulWidget {
  final VIPotatoConfig? initial;
  const VIPotatoBuilderPage({Key? key, this.initial}) : super(key: key);

  @override
  State<VIPotatoBuilderPage> createState() => _VIPotatoBuilderPageState();
}

class _VIPotatoBuilderPageState extends State<VIPotatoBuilderPage> {
  Map<String, List<Trait>> _byCategory = {};
  late VIPotatoConfig _config;
  late final TextEditingController _name;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _config = VIPotatoConfig(
      id: widget.initial?.id,
      name: widget.initial?.name ?? '',
      traits: {...?widget.initial?.traits},
    );
    _name = TextEditingController(text: _config.name);
    _load();
  }

  Future<void> _load() async {
    final byCat = await VIPotatoService.loadTraitsByCategory();
    if (!mounted) return;
    setState(() {
      _byCategory = byCat;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggle(Trait t) {
    setState(() {
      final current = _config.traits[t.category];
      if (current?.id == t.id) {
        _config.traits.remove(t.category); // tap again to clear
      } else {
        _config.traits[t.category] = t;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      _config.name = _name.text;
      final saved = await VIPotatoService.saveAndEquip(_config);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save — try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      appBar: AppBar(
        backgroundColor: Potatuhs.inkDeep,
        elevation: 0,
        title: Text('BUILD YOUR POTATO',
            style: Potatuhs.display(size: 18, spacing: 1.5)),
        actions: [
          if (_config.traits.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _config.traits.clear()),
              child: Text('Clear',
                  style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                VIPotatoAvatar(config: _config, size: 160),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _name,
                    textAlign: TextAlign.center,
                    style: Potatuhs.body(size: 16),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      hintText: 'Name your potato',
                      hintStyle:
                          Potatuhs.body(size: 16, color: Potatuhs.textFaint),
                      isDense: true,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Potatuhs.gold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _traitPicker()),
                _saveBar(),
              ],
            ),
    );
  }

  Widget _traitPicker() {
    if (_byCategory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No traits available right now.\nCheck your connection and try again.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
          ),
        ),
      );
    }
    final categories = _byCategory.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final category = categories[i];
        final traits = _byCategory[category]!;
        final selected = _config.traits[category];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              child: Text(category.toUpperCase(),
                  style: Potatuhs.label(size: 11)),
            ),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: traits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, j) {
                  final t = traits[j];
                  final isOn = selected?.id == t.id;
                  return GestureDetector(
                    onTap: () => _toggle(t),
                    child: Container(
                      width: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOn
                              ? Potatuhs.gold
                              : Colors.white.withValues(alpha: 0.12),
                          width: isOn ? 2.2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        t.imageUrl,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.white24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _saveBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(_error!,
                  style: Potatuhs.body(size: 12.5, color: Potatuhs.orange)),
              const SizedBox(height: 8),
            ],
            PotatuhsButton(
              label: _saving ? 'SAVING…' : 'SAVE & EQUIP',
              onTap: _saving || _config.traits.isEmpty ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
