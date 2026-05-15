import 'package:flutter/material.dart';

/// Loading spinner footer appended below the last row of a paginated list
/// while the next page is in flight. 20×20 spinner with vertical padding so
/// the strip doesn't crowd the last data row.
class EntityListLoadingFooter extends StatelessWidget {
  const EntityListLoadingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
