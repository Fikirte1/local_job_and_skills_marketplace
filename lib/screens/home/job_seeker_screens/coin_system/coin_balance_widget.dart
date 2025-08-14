import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'coin_service.dart';

class CoinBalanceWidget extends StatelessWidget {
  const CoinBalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<int>(
      future: CoinService.getCoinBalance(userId),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0;

        return Chip(
          avatar: const Icon(Icons.monetization_on, size: 18, color: Colors.amber),
          label: Text(
            balance.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.amber.withOpacity(0.2),
        );
      },
    );
  }
}