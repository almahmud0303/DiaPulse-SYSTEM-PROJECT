import 'package:flutter/material.dart';

/// A styled, full-width button for triggering PDF export.
///
/// Shows a loading spinner when [isLoading] is true and disables interaction.
class ExportReportButton extends StatelessWidget {
  const ExportReportButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.teal.withValues(alpha:0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            else
              const Icon(Icons.picture_as_pdf_outlined, size: 22),
            const SizedBox(width: 10),
            Text(isLoading ? 'Generating PDF…' : 'Preview & Export PDF'),
          ],
        ),
      ),
    );
  }
}
