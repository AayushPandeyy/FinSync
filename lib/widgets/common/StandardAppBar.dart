import 'package:flutter/material.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? titleColor;
  final Widget? leading;
  final bool useCustomDesign; // New parameter for modern design

  const StandardAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.titleColor,
    this.leading,
    this.useCustomDesign = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useCustomDesign) {
      // Modern custom design with back button in container
      return Container(
        color: backgroundColor ?? Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              leading ??
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: backgroundColor != null
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: titleColor ?? const Color(0xFF1A1A1A),
                        size: 18,
                      ),
                    ),
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: titleColor ?? const Color(0xFF1A1A1A),
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: titleColor?.withOpacity(0.7) ??
                              const Color(0xFF999999),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 8),
                ...actions!,
              ],
            ],
          ),
        ),
      );
    }

    // Standard AppBar design
    return AppBar(
      backgroundColor: backgroundColor ?? const Color(0xFFF8F8FA),
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: titleColor ?? const Color(0xFF1A1A1A),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF1A1A1A),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => useCustomDesign
      ? const Size.fromHeight(90)
      : const Size.fromHeight(kToolbarHeight);
}
