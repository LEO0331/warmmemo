import 'package:flutter/material.dart';

import '../../core/utils/product_locale.dart';
import 'financial_footing_model.dart';

enum _FootingField {
  liquidCash('liquid_cash', '可動用現金（NT\$）', 'Accessible cash (NT\$)'),
  investments('investments', '其他投資（NT\$）', 'Other investments (NT\$)'),
  nonLiquidAssets('non_liquid_assets', '非流動資產（NT\$）', 'Illiquid assets (NT\$)'),
  liabilities('liabilities', '未償負債（NT\$）', 'Outstanding liabilities (NT\$)'),
  monthlyEssentials(
    'monthly_essentials',
    '每月必要支出（NT\$）',
    'Monthly essentials (NT\$)',
  ),
  targetMonths('target_months', '個人現金緩衝目標（月）', 'Cash buffer target (months)');

  const _FootingField(this.id, this.zh, this.en);

  final String id;
  final String zh;
  final String en;
}

/// This card keeps its entries in memory for the lifetime of the planner.
class FinancialFootingCard extends StatefulWidget {
  const FinancialFootingCard({super.key});

  @override
  State<FinancialFootingCard> createState() => _FinancialFootingCardState();
}

class _FinancialFootingCardState extends State<FinancialFootingCard> {
  final _controllers = {
    for (final field in _FootingField.values) field: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final english = isEnglishProductLocale(context);
    String copy(String zh, String en) => english ? en : zh;

    final theme = Theme.of(context);
    final inputs = {
      for (final entry in _controllers.entries)
        entry.key: parseFinancialFootingInput(entry.value.text),
    };
    final snapshot = FinancialFootingSnapshot(
      liquidCash: inputs[_FootingField.liquidCash]?.value,
      investments: inputs[_FootingField.investments]?.value,
      nonLiquidAssets: inputs[_FootingField.nonLiquidAssets]?.value,
      liabilities: inputs[_FootingField.liabilities]?.value,
      monthlyEssentials: inputs[_FootingField.monthlyEssentials]?.value,
      targetMonths: inputs[_FootingField.targetMonths]?.value,
    );
    final netWorth = snapshot.estimatedNetWorth;
    final cashBuffer = snapshot.cashBufferMonths;
    final unavailable = copy('無法估算', 'Unavailable');
    final netWorthValue = netWorth == null
        ? unavailable
        : 'NT\$${_formatEstimate(context, netWorth)}';
    final bufferEstimate = switch (cashBuffer) {
      null => null,
      > 0 && < 0.01 => copy('少於 0.01', 'less than 0.01'),
      final months => _formatEstimate(context, months),
    };
    final cashBufferValue = switch (bufferEstimate) {
      null => unavailable,
      '1' => copy('1 個月', '1 month'),
      final months => copy('$months 個月', '$months months'),
    };
    final guidance = switch (snapshot.bufferStatus) {
      FinancialBufferStatus.unavailable => copy(
        '目前無法評估現金緩衝或判斷支出是否可負擔。你可以略過財務資料，繼續規劃體驗。',
        'There is too little information to estimate your cash buffer or assess affordability. You can leave these fields blank and continue planning experiences.',
      ),
      FinancialBufferStatus.noTarget => copy(
        '你可以參考現金緩衝月數，思考希望保留多少彈性。是否設定目標由你決定。',
        'Use the cash buffer estimate to think about how much flexibility you want to keep. Choosing a target is optional.',
      ),
      FinancialBufferStatus.belowTarget => copy(
        '現金緩衝低於你選擇的目標。安排較大的非必要支出前，可以先檢視必要開銷、可動用現金與近期付款義務，想想要保留多少彈性。',
        'Your cash buffer is below your chosen target. Before committing to a large discretionary expense, review essential costs, accessible cash, and upcoming obligations to decide how much flexibility to keep.',
      ),
      FinancialBufferStatus.meetsTarget => copy(
        '現金緩衝已達到你選擇的目標。整體財務安全與可負擔程度還取決於其他因素，可以把重視的體驗與未來承諾一起考量。',
        'Your cash buffer meets your chosen target. Financial security and affordability depend on other factors too. Consider the experiences you value alongside your future commitments.',
      ),
    };

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('financial_footing_expansion'),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: Text(
          copy('財務基礎與人生體驗', 'Financial Footing & Meaningful Spending'),
          style: theme.textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy(
                  '人生不同階段，財務上的優先順序也會改變。先了解目前的財務彈性，再安排真正重視的生活體驗。',
                  'Financial priorities change with circumstances. Understand your current flexibility before planning experiences that matter to you.',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                copy(
                  '此區可略過。請填入目前的數字，沒有該項請填 0，留白代表未知。現金只計入可立即動用的存款與現金，房屋等資產請填在非流動資產。',
                  'All fields are optional. Enter current figures. Use 0 for a category you do not have and leave unknown values blank. Accessible cash includes cash and readily accessible savings. Enter property under illiquid assets.',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                copy(
                  '此區資料僅保留在這次使用期間，重新載入即清除。既有規劃草稿使用未加密的瀏覽器本機儲存，同一瀏覽器設定檔的其他使用者可能讀到草稿。',
                  'These entries stay in this session and clear on reload. The existing planner draft uses unencrypted browser storage, which other people using the same browser profile may access.',
                ),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;
                  final width = constraints.maxWidth;
                  final minPairWidth = MediaQuery.textScalerOf(
                    context,
                  ).scale(620);
                  final fieldWidth = width >= minPairWidth
                      ? (width - spacing) / 2
                      : width;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final field in _FootingField.values)
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            key: Key('financial_footing_${field.id}'),
                            controller: _controllers[field],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: field == _FootingField.targetMonths
                                ? TextInputAction.done
                                : TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            enableIMEPersonalizedLearning: false,
                            decoration: InputDecoration(
                              labelText: copy(field.zh, field.en),
                              border: const OutlineInputBorder(),
                              errorMaxLines: 3,
                              errorText: inputs[field]?.isInvalid == true
                                  ? copy(
                                      '請輸入 0 至 999,999,999,999，最多兩位小數。',
                                      'Enter 0 to 999,999,999,999 with up to two decimal places.',
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                copy(
                  '現金緩衝目標是你自選的規劃假設，可隨情況調整。',
                  'Your cash buffer target is a personal planning assumption you can adjust as circumstances change.',
                ),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                copy(
                  '目前估計淨資產：$netWorthValue',
                  'Current estimated net worth: $netWorthValue',
                ),
                key: const Key('financial_footing_net_worth'),
                style: theme.textTheme.titleSmall,
              ),
              Text(
                copy(
                  '可動用現金緩衝：$cashBufferValue',
                  'Liquid cash buffer: $cashBufferValue',
                ),
                key: const Key('financial_footing_cash_buffer'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                copy(
                  '淨資產需要四項資產與負債資料。現金緩衝需要可動用現金與大於 0 的每月必要支出。月數顯示至小數第二位，目標比較以未四捨五入的結果為準。未來收入、照護費用、稅金及其他義務仍可能變動。',
                  'Net worth needs all four asset and liability entries. The buffer needs accessible cash and monthly essentials above zero. Displayed months are rounded to two decimal places. The target comparison uses the unrounded estimate. Future income, care costs, taxes, and other obligations may change.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                copy('財務規劃情境', 'Financial planning context'),
                style: theme.textTheme.titleSmall,
              ),
              Text(guidance, key: const Key('financial_footing_context')),
              if (snapshot.hasReportedLiabilities) ...[
                const SizedBox(height: 8),
                Text(
                  copy(
                    '你有填寫負債。負債金額、還款條件與費用都可能影響財務彈性。',
                    'You reported liabilities. Their balances, repayment terms, and costs can affect your flexibility.',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                copy('你重視的體驗', 'Experiences you value'),
                style: theme.textTheme.titleSmall,
              ),
              Text(
                copy(
                  '家庭、旅行、學習或貢獻，哪些對你最有意義？哪些體驗有時間上的限制？它們需要多少時間或金錢？規模小一點能帶來相近的意義嗎？你希望保留哪些資源或照顧哪些承諾？',
                  'What matters most to you in family, travel, learning, or contribution? Which experiences are time-sensitive? How much time or money would they take? Could a smaller version be just as meaningful? What resources or commitments do you want to protect?',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEstimate(BuildContext context, double value) {
    final parts = value.abs().toStringAsFixed(2).split('.');
    final whole = MaterialLocalizations.of(
      context,
    ).formatDecimal(int.parse(parts[0]));
    final fraction = parts[1].replaceFirst(RegExp(r'0+$'), '');
    final sign = value < 0 ? '-' : '';
    return fraction.isEmpty ? '$sign$whole' : '$sign$whole.$fraction';
  }
}
