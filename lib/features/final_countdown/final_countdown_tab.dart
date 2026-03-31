import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/common_widgets.dart';

enum _AmountKind { oneTime, annual }

enum _AnnualPhase { allYears, beforeRetire, afterRetire }

class _PlanItem {
  _PlanItem({
    required String name,
    required String amount,
    this.kind = _AmountKind.oneTime,
    this.phase = _AnnualPhase.allYears,
  }) : nameController = TextEditingController(text: name),
       amountController = TextEditingController(text: amount);

  final TextEditingController nameController;
  final TextEditingController amountController;
  _AmountKind kind;
  _AnnualPhase phase;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': nameController.text,
      'amount': amountController.text,
      'kind': kind.name,
      'phase': phase.name,
    };
  }

  static _PlanItem fromJson(Map<String, dynamic> json) {
    return _PlanItem(
      name: (json['name'] as String?) ?? '',
      amount: (json['amount'] as String?) ?? '0',
      kind: _AmountKind.values.firstWhere(
        (v) => v.name == json['kind'],
        orElse: () => _AmountKind.oneTime,
      ),
      phase: _AnnualPhase.values.firstWhere(
        (v) => v.name == json['phase'],
        orElse: () => _AnnualPhase.allYears,
      ),
    );
  }

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return const TextEditingValue(text: '');
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(raw)) return oldValue;

    final parts = raw.split('.');
    final integerPart = parts.first;
    final decimalPart = parts.length > 1 ? parts[1] : '';
    final formattedInt = _thousands(integerPart);
    final text = decimalPart.isEmpty ? formattedInt : '$formattedInt.$decimalPart';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _thousands(String input) {
    if (input.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final reverseIndex = input.length - i;
      buffer.write(input[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

class FinalCountdownTab extends StatefulWidget {
  const FinalCountdownTab({super.key});

  @override
  State<FinalCountdownTab> createState() => _FinalCountdownTabState();
}

class _FinalCountdownTabState extends State<FinalCountdownTab> {
  static const _prefsKey = 'final_countdown_tab_v1';

  late final TextEditingController _currentAgeController;
  late final TextEditingController _lifeExpectancyController;
  late final TextEditingController _retireYearController;

  final List<_PlanItem> _costItems = <_PlanItem>[];
  final List<_PlanItem> _assetItems = <_PlanItem>[];
  final _formatter = _CurrencyInputFormatter();
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    final nowYear = DateTime.now().year;
    _currentAgeController = TextEditingController(text: '35');
    _lifeExpectancyController = TextEditingController(text: '85');
    _retireYearController = TextEditingController(text: '${nowYear + 25}');
    _seedDefaults();
    _loadDraft();
  }

  void _seedDefaults() {
    _costItems
      ..clear()
      ..addAll(<_PlanItem>[
        _PlanItem(name: '旅行計畫', amount: '120,000'),
        _PlanItem(
          name: '規律運動',
          amount: '36,000',
          kind: _AmountKind.annual,
          phase: _AnnualPhase.allYears,
        ),
        _PlanItem(
          name: '家庭禮物',
          amount: '30,000',
          kind: _AmountKind.annual,
          phase: _AnnualPhase.afterRetire,
        ),
      ]);
    _assetItems
      ..clear()
      ..addAll(<_PlanItem>[
        _PlanItem(name: '房產估值', amount: '8,000,000'),
        _PlanItem(name: '股票資產', amount: '2,500,000'),
        _PlanItem(
          name: '年度收入',
          amount: '900,000',
          kind: _AmountKind.annual,
          phase: _AnnualPhase.beforeRetire,
        ),
      ]);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final costs = ((map['costItems'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_PlanItem.fromJson)
          .toList();
      final assets = ((map['assetItems'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_PlanItem.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        final currentAge = (map['currentAge'] as String?)?.trim();
        final life = (map['lifeExpectancy'] as String?)?.trim();
        final retire = (map['retireYear'] as String?)?.trim();
        if (currentAge != null && currentAge.isNotEmpty) {
          _currentAgeController.text = currentAge;
        }
        if (life != null && life.isNotEmpty) {
          _lifeExpectancyController.text = life;
        }
        if (retire != null && retire.isNotEmpty) {
          _retireYearController.text = retire;
        }
        if (costs.isNotEmpty) {
          for (final item in _costItems) {
            item.dispose();
          }
          _costItems
            ..clear()
            ..addAll(costs);
        }
        if (assets.isNotEmpty) {
          for (final item in _assetItems) {
            item.dispose();
          }
          _assetItems
            ..clear()
            ..addAll(assets);
        }
      });
    } catch (_) {
      // Ignore invalid local cache.
    }
  }

  void _queueSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'currentAge': _currentAgeController.text.trim(),
        'lifeExpectancy': _lifeExpectancyController.text.trim(),
        'retireYear': _retireYearController.text.trim(),
        'costItems': _costItems.map((item) => item.toJson()).toList(),
        'assetItems': _assetItems.map((item) => item.toJson()).toList(),
      };
      await prefs.setString(_prefsKey, jsonEncode(payload));
    });
  }

  int _readInt(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  double _readAmount(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;
  }

  double _sumItems(
    List<_PlanItem> items, {
    required int allYears,
    required int beforeRetire,
    required int afterRetire,
  }) {
    var total = 0.0;
    for (final item in items) {
      final amount = _readAmount(item.amountController);
      if (amount <= 0) continue;
      if (item.kind == _AmountKind.oneTime) {
        total += amount;
        continue;
      }
      final years = switch (item.phase) {
        _AnnualPhase.allYears => allYears,
        _AnnualPhase.beforeRetire => beforeRetire,
        _AnnualPhase.afterRetire => afterRetire,
      };
      total += amount * years;
    }
    return total;
  }

  String _currency(double value) {
    final rounded = value.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return rounded < 0 ? 'NT\$ -${buffer.toString()}' : 'NT\$ ${buffer.toString()}';
  }

  String? _amountError(String text) {
    final normalized = text.replaceAll(',', '').trim();
    if (normalized.isEmpty) return '請輸入金額';
    final value = double.tryParse(normalized);
    if (value == null) return '請輸入有效數字';
    if (value < 0) return '金額不可為負數';
    return null;
  }

  void _refreshAndSave() {
    setState(() {});
    _queueSave();
  }

  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;
    final currentAge = math.max(0, _readInt(_currentAgeController, 35));
    final life = math.max(0, _readInt(_lifeExpectancyController, 85));
    final retireYear = _readInt(_retireYearController, nowYear + 25);
    final remainingYears = math.max(0, life - currentAge);
    final beforeRetire = math.min(math.max(0, retireYear - nowYear), remainingYears);
    final afterRetire = math.max(0, remainingYears - beforeRetire);

    final totalCost = _sumItems(
      _costItems,
      allYears: remainingYears,
      beforeRetire: beforeRetire,
      afterRetire: afterRetire,
    );
    final totalAsset = _sumItems(
      _assetItems,
      allYears: remainingYears,
      beforeRetire: beforeRetire,
      afterRetire: afterRetire,
    );
    final net = totalAsset - totalCost;
    final annualTarget = remainingYears > 0 ? totalAsset / remainingYears : 0.0;
    final monthlyTarget = annualTarget / 12;
    final balanceBase = math.max(1.0, math.max(totalAsset.abs(), totalCost.abs()));
    final score = (1 - (net.abs() / balanceBase)).clamp(0.0, 1.0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '人生倒數與零結餘規劃',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '設定退休年份與預估壽命，讓資產與體驗支出在生命終點前盡量接近零結餘。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '倒數參數',
              icon: Icons.hourglass_bottom_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _numberField(
                    key: const Key('current_age_field'),
                    label: '目前年齡',
                    controller: _currentAgeController,
                  ),
                  const SizedBox(height: 10),
                  _numberField(
                    key: const Key('life_expectancy_field'),
                    label: '預估壽命（歲）',
                    controller: _lifeExpectancyController,
                  ),
                  const SizedBox(height: 10),
                  _numberField(
                    key: const Key('retire_year_field'),
                    label: '退休年份',
                    controller: _retireYearController,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricChip('剩餘年數', '$remainingYears 年'),
                      _metricChip('距離退休', '$beforeRetire 年'),
                      _metricChip('退休後年數', '$afterRetire 年'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                if (!wide) {
                  return Column(
                    children: [
                      _buildCostPanel(),
                      const SizedBox(height: 16),
                      _buildAssetPanel(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCostPanel()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAssetPanel()),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '零結餘結果',
              icon: Icons.balance_outlined,
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _metricChip('總資產', _currency(totalAsset), key: const Key('summary_total_asset')),
                        _metricChip('總支出', _currency(totalCost), key: const Key('summary_total_cost')),
                        _metricChip('差額（資產 - 支出）', _currency(net), key: const Key('summary_net')),
                        _metricChip('建議年預算', _currency(annualTarget)),
                        _metricChip('建議月預算', _currency(monthlyTarget)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: score,
                        backgroundColor: const Color(0xFFF1E4DA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      net.abs() < 1000
                          ? '很接近零結餘，規劃相當平衡。'
                          : net > 0
                          ? '目前有剩餘資金，可增加體驗型支出。'
                          : '目前預估不足，建議補強資產或下修支出。',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostPanel() {
    return SectionCard(
      title: '左側：體驗與生活成本（支出）',
      icon: Icons.trending_down_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickAddChip('加入旅行', Icons.flight_takeoff_outlined, () {
                _costItems.add(
                  _PlanItem(
                    name: '年度旅行',
                    amount: '120,000',
                    kind: _AmountKind.annual,
                    phase: _AnnualPhase.allYears,
                  ),
                );
                _refreshAndSave();
              }),
              _quickAddChip('加入健康', Icons.directions_run_outlined, () {
                _costItems.add(
                  _PlanItem(
                    name: '健康運動',
                    amount: '36,000',
                    kind: _AmountKind.annual,
                    phase: _AnnualPhase.afterRetire,
                  ),
                );
                _refreshAndSave();
              }),
              _quickAddChip('加入贈與', Icons.redeem_outlined, () {
                _costItems.add(_PlanItem(name: '家庭贈與', amount: '500,000'));
                _refreshAndSave();
              }),
            ],
          ),
          const SizedBox(height: 12),
          if (_costItems.isEmpty)
            const EmptyStateCard(
              title: '尚未新增支出項目',
              description: '先加入一筆想實現的體驗或生活成本。',
              icon: Icons.wallet_outlined,
            )
          else
            Column(
              children: List.generate(_costItems.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _itemEditor(
                    item: _costItems[index],
                    onDelete: () {
                      final target = _costItems.removeAt(index);
                      target.dispose();
                      _refreshAndSave();
                    },
                  ),
                );
              }),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () {
              _costItems.add(_PlanItem(name: '', amount: '0'));
              _refreshAndSave();
            },
            icon: const Icon(Icons.add),
            label: const Text('新增支出項目'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetPanel() {
    return SectionCard(
      title: '右側：現有資產與收入',
      icon: Icons.trending_up_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickAddChip('加入存款', Icons.account_balance_wallet_outlined, () {
                _assetItems.add(_PlanItem(name: '存款現金', amount: '1,000,000'));
                _refreshAndSave();
              }),
              _quickAddChip('加入股票', Icons.show_chart_outlined, () {
                _assetItems.add(_PlanItem(name: '股票資產', amount: '800,000'));
                _refreshAndSave();
              }),
              _quickAddChip('加入收入', Icons.work_outline, () {
                _assetItems.add(
                  _PlanItem(
                    name: '年度收入',
                    amount: '900,000',
                    kind: _AmountKind.annual,
                    phase: _AnnualPhase.beforeRetire,
                  ),
                );
                _refreshAndSave();
              }),
            ],
          ),
          const SizedBox(height: 12),
          if (_assetItems.isEmpty)
            const EmptyStateCard(
              title: '尚未新增資產項目',
              description: '先加入可用資產或收入來源。',
              icon: Icons.savings_outlined,
            )
          else
            Column(
              children: List.generate(_assetItems.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _itemEditor(
                    item: _assetItems[index],
                    onDelete: () {
                      final target = _assetItems.removeAt(index);
                      target.dispose();
                      _refreshAndSave();
                    },
                  ),
                );
              }),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () {
              _assetItems.add(_PlanItem(name: '', amount: '0'));
              _refreshAndSave();
            },
            icon: const Icon(Icons.add),
            label: const Text('新增資產項目'),
          ),
        ],
      ),
    );
  }

  Widget _quickAddChip(String label, IconData icon, VoidCallback onTap) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        if (selected) onTap();
      },
    );
  }

  Widget _itemEditor({
    required _PlanItem item,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D7CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.nameController,
                  onChanged: (_) => _refreshAndSave(),
                  decoration: const InputDecoration(labelText: '項目名稱', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '刪除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.amountController,
            onChanged: (_) => _refreshAndSave(),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              _formatter,
            ],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '金額（NT\$）',
              isDense: true,
              errorText: _amountError(item.amountController.text),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('單次金額'),
                selected: item.kind == _AmountKind.oneTime,
                onSelected: (selected) {
                  if (!selected) return;
                  item.kind = _AmountKind.oneTime;
                  item.phase = _AnnualPhase.allYears;
                  _refreshAndSave();
                },
              ),
              ChoiceChip(
                label: const Text('每年金額'),
                selected: item.kind == _AmountKind.annual,
                onSelected: (selected) {
                  if (!selected) return;
                  item.kind = _AmountKind.annual;
                  _refreshAndSave();
                },
              ),
            ],
          ),
          if (item.kind == _AmountKind.annual) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('全期間'),
                  selected: item.phase == _AnnualPhase.allYears,
                  onSelected: (selected) {
                    if (!selected) return;
                    item.phase = _AnnualPhase.allYears;
                    _refreshAndSave();
                  },
                ),
                ChoiceChip(
                  label: const Text('退休前'),
                  selected: item.phase == _AnnualPhase.beforeRetire,
                  onSelected: (selected) {
                    if (!selected) return;
                    item.phase = _AnnualPhase.beforeRetire;
                    _refreshAndSave();
                  },
                ),
                ChoiceChip(
                  label: const Text('退休後'),
                  selected: item.phase == _AnnualPhase.afterRetire,
                  onSelected: (selected) {
                    if (!selected) return;
                    item.phase = _AnnualPhase.afterRetire;
                    _refreshAndSave();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberField({
    Key? key,
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => _refreshAndSave(),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }

  Widget _metricChip(String label, String value, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E5D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label：$value'),
    );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _currentAgeController.dispose();
    _lifeExpectancyController.dispose();
    _retireYearController.dispose();
    for (final item in _costItems) {
      item.dispose();
    }
    for (final item in _assetItems) {
      item.dispose();
    }
    super.dispose();
  }
}
