import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF7F8FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F3F5);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryPurple = Color(0xFF2563EB);
  static const Color cyan = Color(0xFF0891B2);
  static const Color income = Color(0xFF16A34A);
  static const Color expense = Color(0xFFDC2626);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  static const List<Color> bluePurpleGradient = <Color>[
    Color(0xFF111827),
    Color(0xFF111827),
  ];

  static const List<Color> deepGradient = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF7F8FA),
  ];

  static const List<Color> accountGradients = <Color>[
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF475569),
  ];
}

class AppCategoryStyle {
  const AppCategoryStyle({
    required this.label,
    required this.iconKey,
    required this.color,
  });

  final String label;
  final String iconKey;
  final Color color;
}

const List<AppCategoryStyle> defaultExpenseCategories =
    <AppCategoryStyle>[
  AppCategoryStyle(label: '餐饮', iconKey: 'restaurant', color: Color(0xFFFB7185)),
  AppCategoryStyle(label: '购物', iconKey: 'cart', color: Color(0xFFF59E0B)),
  AppCategoryStyle(label: '交通', iconKey: 'transit', color: Color(0xFF38BDF8)),
  AppCategoryStyle(label: '娱乐', iconKey: 'movie', color: Color(0xFFA78BFA)),
  AppCategoryStyle(label: '住房', iconKey: 'home', color: Color(0xFFF472B6)),
  AppCategoryStyle(label: '水电', iconKey: 'bolt', color: Color(0xFFFBBF24)),
  AppCategoryStyle(label: '学习', iconKey: 'school', color: Color(0xFF60A5FA)),
  AppCategoryStyle(label: '医疗', iconKey: 'medical', color: Color(0xFF34D399)),
  AppCategoryStyle(label: '旅行', iconKey: 'flight', color: Color(0xFF22D3EE)),
  AppCategoryStyle(label: '其他', iconKey: 'more', color: Color(0xFF94A3B8)),
];

const List<AppCategoryStyle> defaultIncomeCategories =
    <AppCategoryStyle>[
  AppCategoryStyle(label: '工资', iconKey: 'salary', color: Color(0xFF34D399)),
  AppCategoryStyle(label: '生活费', iconKey: 'wallet', color: Color(0xFF2563EB)),
  AppCategoryStyle(label: '奖金', iconKey: 'gift', color: Color(0xFFF59E0B)),
  AppCategoryStyle(label: '投资', iconKey: 'trending', color: Color(0xFF38BDF8)),
  AppCategoryStyle(label: '红包', iconKey: 'redpacket', color: Color(0xFFFB7185)),
  AppCategoryStyle(label: '兼职', iconKey: 'parttime', color: Color(0xFFA78BFA)),
  AppCategoryStyle(label: '其他', iconKey: 'more', color: Color(0xFF94A3B8)),
];

class AppIcons {
  AppIcons._();

  static const Map<String, IconData> _icons = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'cart': Icons.shopping_cart_rounded,
    'transit': Icons.directions_subway_rounded,
    'movie': Icons.movie_rounded,
    'home': Icons.home_rounded,
    'bolt': Icons.bolt_rounded,
    'school': Icons.school_rounded,
    'medical': Icons.medical_services_rounded,
    'flight': Icons.flight_rounded,
    'more': Icons.more_horiz_rounded,
    'salary': Icons.payments_rounded,
    'gift': Icons.card_giftcard_rounded,
    'trending': Icons.trending_up_rounded,
    'redpacket': Icons.redeem_rounded,
    'parttime': Icons.work_rounded,
    'wechat': Icons.chat_rounded,
    'alipay': Icons.account_balance_wallet_rounded,
    'cash': Icons.payments_rounded,
    'bank': Icons.account_balance_rounded,
    'credit': Icons.credit_card_rounded,
    'saving': Icons.savings_rounded,
    'investment': Icons.show_chart_rounded,
    'wallet': Icons.wallet_rounded,
    'other': Icons.category_rounded,
  };

  static IconData forKey(String key) => _icons[key] ?? Icons.category_rounded;
}

class AppConstants {
  AppConstants._();

  static const String demoUserName = '林夏';
  static const String demoUserEmail = 'linxia@example.com';
}
