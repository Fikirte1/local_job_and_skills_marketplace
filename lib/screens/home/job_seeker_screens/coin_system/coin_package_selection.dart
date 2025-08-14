import 'package:flutter/material.dart';
import 'package:local_job_and_skills_marketplace/screens/home/job_seeker_screens/coin_system/payment_details_screen.dart';

import 'coin_balance_widget.dart';

class CoinPackageSelectionScreen extends StatefulWidget {
  const CoinPackageSelectionScreen({super.key});

  @override
  State<CoinPackageSelectionScreen> createState() => _CoinPackageSelectionScreenState();
}

class _CoinPackageSelectionScreenState extends State<CoinPackageSelectionScreen> {
  final Map<String, Map<String, dynamic>> coinPackages = {
    '10': {'coins': 10, 'price': 5.00, 'bonus': 0},
    '25': {'coins': 25, 'price': 10.00, 'bonus': 5},
    '50': {'coins': 50, 'price': 18.00, 'bonus': 10},
    '100': {'coins': 100, 'price': 30.00, 'bonus': 25},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     /* appBar: AppBar(
        title: const Text('Purchase Coins'),
        actions: const [
          CoinBalanceWidget(),
          SizedBox(width: 8),
        ],
      ),*/
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a Coin Package',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...coinPackages.entries.map((entry) => _buildCoinPackageCard(
            context,
            title: '${entry.value['coins']} Coins',
            price: '\$${entry.value['price']}',
            coins: entry.value['coins'],
            bonus: entry.value['bonus'],
          )),
        ],
      ),
    );
  }

  Widget _buildCoinPackageCard(
      BuildContext context, {
        required String title,
        required String price,
        required int coins,
        required int bonus,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (bonus > 0) ...[
              const SizedBox(height: 8),
              Text(
                '+ $bonus Bonus Coins!',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectPackage(context, coins, bonus),
              child: const Text('Select Package'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPackage(BuildContext context, int coins, int bonus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(
          coins: coins,
          bonus: bonus,
          price: coinPackages['$coins']?['price'] ?? 0.0,
        ),
      ),
    );
  }
}