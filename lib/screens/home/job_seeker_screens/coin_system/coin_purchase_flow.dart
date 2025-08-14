import 'package:flutter/material.dart';

import 'coin_package_selection.dart';

class CoinPurchaseFlow extends StatelessWidget {
  const CoinPurchaseFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CoinPackageSelectionScreen(),
    );
  }
}