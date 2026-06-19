import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showCustomSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 4),
      padding: EdgeInsets.zero,
      content: Builder(
        builder: (snackBarContext) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 14.0,
                  bottom: 14.0,
                  left: 16.0,
                  right: 42.0,
                ),
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    ScaffoldMessenger.of(snackBarContext).hideCurrentSnackBar();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
