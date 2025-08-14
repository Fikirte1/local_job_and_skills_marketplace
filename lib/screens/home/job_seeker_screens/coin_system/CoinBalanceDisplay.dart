// Add this new widget in your widgets folder (lib/widgets/coin_balance_display.dart)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'coin_service.dart';

class CoinBalanceDisplay extends StatelessWidget {
  const CoinBalanceDisplay({super.key, this.size = 'medium'});
  final String size; // 'small', 'medium', or 'large'

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<int>(
      future: CoinService.getCoinBalance(userId),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0;
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                color: Colors.amber[800],
                size: size == 'large' ? 28 : (size == 'medium' ? 24 : 20),
              ),
              const SizedBox(width: 8),
              Text(
                balance.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                  fontSize: size == 'large' ? 20 : (size == 'medium' ? 18 : 16),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Coins',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.amber[800],
                  fontSize: size == 'large' ? 16 : (size == 'medium' ? 14 : 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}