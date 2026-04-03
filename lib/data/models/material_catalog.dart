class MaterialOption {
  const MaterialOption({
    required this.code,
    required this.label,
    required this.tier,
    required this.priceBand,
    required this.description,
  });

  final String code;
  final String label;
  final String tier;
  final String priceBand;
  final String description;
}

const List<MaterialOption> kMaterialOptionsV1 = [
  MaterialOption(
    code: 'granite_black',
    label: '黑花崗石',
    tier: 'Premium',
    priceBand: 'NT\$ 60,000+',
    description: '耐候高，適合戶外長期設置。',
  ),
  MaterialOption(
    code: 'granite_gray',
    label: '灰花崗石',
    tier: 'Standard',
    priceBand: 'NT\$ 42,000+',
    description: '質地穩定、成本平衡。',
  ),
  MaterialOption(
    code: 'marble_white',
    label: '白大理石',
    tier: 'Premium',
    priceBand: 'NT\$ 68,000+',
    description: '視覺柔和，需定期保養。',
  ),
  MaterialOption(
    code: 'bronze_plate',
    label: '青銅牌',
    tier: 'Standard',
    priceBand: 'NT\$ 28,000+',
    description: '碑牌常見材質，施工彈性高。',
  ),
  MaterialOption(
    code: 'stainless_plate',
    label: '不鏽鋼牌',
    tier: 'Basic',
    priceBand: 'NT\$ 18,000+',
    description: '成本較低，適合入門方案。',
  ),
  MaterialOption(
    code: 'wood_indoor',
    label: '室內木質牌',
    tier: 'Basic',
    priceBand: 'NT\$ 12,000+',
    description: '適合室內追思空間展示。',
  ),
];
