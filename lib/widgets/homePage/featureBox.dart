import 'package:flutter/material.dart';

class FeatureBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  const FeatureBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    
    final color = accentColor ?? const Color(0xFF4A90E2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width * 0.25,
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              icon,
              color: color.withOpacity(0.7),
              size: width * 0.06,
            ),
            
            SizedBox(height: width * 0.03),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: width * 0.030,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            
            
            // Action indicator
            // Row(
            //   children: [
            //     Text(
            //       "View",
            //       style: TextStyle(
            //         color: color.withOpacity(0.6),
            //         fontSize: width * 0.03,
            //         fontWeight: FontWeight.w500,
            //       ),
            //     ),
            //     SizedBox(width: width * 0.01),
            //     Icon(
            //       Icons.arrow_forward,
            //       color: color.withOpacity(0.6),
            //       size: width * 0.035,
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}