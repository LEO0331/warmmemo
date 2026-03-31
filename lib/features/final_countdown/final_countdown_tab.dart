import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';

enum _AmountKind { oneTime, annual }

class _PlanItem {
  _PlanItem({
    required String name,
    required String amount,
    this.kind = _AmountKind.oneTime,
  }) : nameController = TextEditingController(text: name),
       amountController = TextEditingController(text: amount);

  final TextEditingController nameController;
  final TextEditingController amountController;
  _AmountKind kind;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class FinalCountdownTab extends StatefulWidget {
  const FinalCountdownTab({super.key});

  @override
  State<FinalCountdownTab> createState() => _FinalCountdownTabState();
}

class _FinalCountdownTabState extends State<FinalCountdownTab> {
  late final TextEditingController _currentAgeController;
  late final TextEditingController _lifeExpectancyAgeController;
  late final TextEditingController _retireYearController;

  final List<_PlanItem> _costItems = <_PlanItem>[];
  final List<_PlanItem> _assetItems = <_PlanItem>[];

  @override
  void initState() {
    super.initState();
    final nowYear = DateTime.now().year;
    _currentAgeController = TextEditingController(text: '35');
    _lifeExpectancyAgeController = TextEditingController(text: '85');
    _retireYearController = TextEditingController(text: '${nowYear + 25}');

    _costItems.addAll(<_PlanItem>[
      _PlanItem(name: '旅行計畫', amount: '120000', kind: _AmountKind.oneTime),
      _PlanItem(name: '規律運動', amount: '36000', kind: _AmountKind.annual),
      _PlanItem(name: '家庭禮物', amount: '30000', kind: _AmountKind.annual),
    ]);
    _assetItems.addAll(<_PlanItem>[
      _PlanItem(name: '房產估值', amount: '8000000', kind: _AmountKind.oneTime),
      _PlanItem(name: '股票資產', amount: '2500000', kind: _AmountKind.oneTime),
      _PlanItem(name: '年度收入', amount: '900000', kind: _AmountKind.annual),
    ]);
  }

  @override
  void dispose() {
    _currentAgeController.dispose();
    _lifeExpectancyAgeController.dispose();
    _retireYearController.dispose();
    for (final item in _costItems) {
      item.dispose();
    }
    for (final item in _assetItems) {
      item.dispose();
    }
    super.dispose();
  }

  int _readInt(TextEditingController controller, {required int fallback}) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  double _readDouble(TextEditingController controller) {
    final normalized = controller.text.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  double _sumItems(List<_PlanItem> items, {required int remainingYears}) {
    var sum = 0.0;
    for (final item in items) {
      final amount = _readDouble(item.amountController);
      if (amount <= 0) continue;
      sum += item.kind == _AmountKind.oneTime ? amount : amount * remainingYears;
    }
    return sum;
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
    final withSign = rounded < 0 ? '-${buffer.toString()}' : buffer.toString();
    return 'NT\$ $withSign';
  }

  void _addCostItem() {
    setState(() {
      _costItems.add(_PlanItem(name: '', amount: '0'));
    });
  }

  void _addAssetItem() {
    setState(() {
      _assetItems.add(_PlanItem(name: '', amount: '0'));
    });
  }

  void _removeCostItem(int index) {
    setState(() {
      final target = _costItems.removeAt(index);
      target.dispose();
    });
  }

  void _removeAssetItem(int index) {
    setState(() {
      final target = _assetItems.removeAt(index);
      target.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;
    final currentAge = math.max(0, _readInt(_currentAgeController, fallback: 35));
    final lifeExpectancyAge = math.max(
      0,
      _readInt(_lifeExpectancyAgeController, fallback: 85),
    );
    final retireYear = _readInt(_retireYearController, fallback: nowYear + 25);

    final remainingYears = math.max(0, lifeExpectancyAge - currentAge);
    final yearsToRetire = math.max(0, retireYear - nowYear);
    final estimatedRetireAge = currentAge + yearsToRetire;
    final yearsAfterRetire = math.max(0, lifeExpectancyAge - estimatedRetireAge);

    final totalCost = _sumItems(_costItems, remainingYears: remainingYears);
    final totalAsset = _sumItems(_assetItems, remainingYears: remainingYears);
    final net = totalAsset - totalCost;
    final annualTarget = remainingYears > 0 ? totalAsset / remainingYears : 0.0;
    final monthlyTarget = annualTarget / 12;
    final balanceBase = math.max(1.0, math.max(totalAsset.abs(), totalCost.abs()));
    final dieWithZeroScore = (1 - (net.abs() / balanceBase)).clamp(0.0, 1.0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '人生倒數與零結餘規劃',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '設定退休年份與預估壽命，把「左側支出」與「右側資產」對齊，目標是在生命終點前接近零結餘。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '倒數參數',
              icon: Icons.hourglass_bottom_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                label: '目前年齡',
                                controller: _currentAgeController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _numberField(
                                label: '預估壽命（歲）',
                                controller: _lifeExpectancyAgeController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _numberField(
                                label: '退休年份',
                                controller: _retireYearController,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _numberField(label: '目前年齡', controller: _currentAgeController),
                          const SizedBox(height: 12),
                          _numberField(
                            label: '預估壽命（歲）',
                            controller: _lifeExpectancyAgeController,
                          ),
                          const SizedBox(height: 12),
                          _numberField(label: '退休年份', controller: _retireYearController),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricChip('剩餘年數', '$remainingYears 年'),
                      _metricChip('距離退休', '$yearsToRetire 年'),
                      _metricChip('退休後年數', '$yearsAfterRetire 年'),
                    ],
                  ),
                  if (lifeExpectancyAge <= currentAge)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        '提醒：預估壽命需大於目前年齡，才能計算有效的剩餘年數。',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  if (retireYear < nowYear)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '提醒：退休年份早於今年，系統會視為已退休。',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCostPanel(remainingYears)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildAssetPanel(remainingYears)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildCostPanel(remainingYears),
                    const SizedBox(height: 16),
                    _buildAssetPanel(remainingYears),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '零結餘結果',
              icon: Icons.balance_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricChip('總資產', _currency(totalAsset)),
                      _metricChip('總支出', _currency(totalCost)),
                      _metricChip('差額（資產 - 支出）', _currency(net)),
                      _metricChip('建議年預算', _currency(annualTarget)),
                      _metricChip('建議月預算', _currency(monthlyTarget)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value: dieWithZeroScore,
                      backgroundColor: const Color(0xFFF1E4DA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    net.abs() < 1000
                        ? '很接近零結餘，規劃相當平衡。'
                        : net > 0
                        ? '目前有剩餘資金，可增加體驗型支出（旅行、健康、陪伴）。'
                        : '目前預估不足，建議補強資產或下修部分支出。',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostPanel(int remainingYears) {
    return SectionCard(
      title: '左側：體驗與生活成本（支出）',
      icon: Icons.trending_down_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '例如：旅行、禮物、規律運動、學習與興趣。年度項目會乘上剩餘年數（$remainingYears 年）。',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _costItems.add(
                      _PlanItem(name: '年度旅行', amount: '120000', kind: _AmountKind.annual),
                    );
                  });
                },
                icon: const Icon(Icons.flight_takeoff_outlined),
                label: const Text('加入旅行'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _costItems.add(
                      _PlanItem(name: '健康運動', amount: '36000', kind: _AmountKind.annual),
                    );
                  });
                },
                icon: const Icon(Icons.directions_run_outlined),
                label: const Text('加入健康'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _costItems.add(
                      _PlanItem(name: '家庭贈與', amount: '500000', kind: _AmountKind.oneTime),
                    );
                  });
                },
                icon: const Icon(Icons.redeem_outlined),
                label: const Text('加入贈與'),
              ),
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
                    onDelete: () => _removeCostItem(index),
                  ),
                );
              }),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: _addCostItem,
            icon: const Icon(Icons.add),
            label: const Text('新增支出項目'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetPanel(int remainingYears) {
    return SectionCard(
      title: '右側：現有資產與收入',
      icon: Icons.trending_up_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '例如：房產、股票、存款、退休前後收入。年度項目會乘上剩餘年數（$remainingYears 年）。',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _assetItems.add(
                      _PlanItem(name: '存款現金', amount: '1000000', kind: _AmountKind.oneTime),
                    );
                  });
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('加入存款'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _assetItems.add(
                      _PlanItem(name: '股票資產', amount: '800000', kind: _AmountKind.oneTime),
                    );
                  });
                },
                icon: const Icon(Icons.show_chart_outlined),
                label: const Text('加入股票'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _assetItems.add(
                      _PlanItem(name: '年度收入', amount: '900000', kind: _AmountKind.annual),
                    );
                  });
                },
                icon: const Icon(Icons.work_outline),
                label: const Text('加入收入'),
              ),
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
                    onDelete: () => _removeAssetItem(index),
                  ),
                );
              }),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: _addAssetItem,
            icon: const Icon(Icons.add),
            label: const Text('新增資產項目'),
          ),
        ],
      ),
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
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '項目名稱',
                    isDense: true,
                  ),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.amountController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '金額（NT）',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<_AmountKind>(
                  initialValue: item.kind,
                  decoration: const InputDecoration(
                    labelText: '計算方式',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _AmountKind.oneTime,
                      child: Text('單次金額'),
                    ),
                    DropdownMenuItem(
                      value: _AmountKind.annual,
                      child: Text('每年金額'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => item.kind = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E5D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label：$value'),
    );
  }
}
