import 'package:flutter/material.dart';

class HistoryLoadingState extends StatelessWidget {
  const HistoryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
