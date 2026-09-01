import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  
  const SubHeader({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      centerTitle: false,
      actions: actions,
      shape: const Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1.0)),
    );
  }
}
