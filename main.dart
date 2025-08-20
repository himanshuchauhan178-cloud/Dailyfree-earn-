
import 'package:flutter/material.dart';
import 'services/wallet_service.dart';
import 'services/ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WalletService.instance.init();
  await AdsService.instance.init(); // AdMob (test)
  runApp(const DailyFreeEarnApp());
}

class DailyFreeEarnApp extends StatelessWidget {
  const DailyFreeEarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyFree Earn',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF16A34A), // green
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DailyFree Earn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BalanceCard(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EarnScreen()),
                );
              },
              child: const Text('🎬 Watch Ad & Earn'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WithdrawScreen()),
                );
              },
              child: const Text('💳 Withdraw (Mock UPI)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RulesScreen()),
                );
              },
              child: const Text('📜 Earning Rules'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  const _BalanceCard();

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  @override
  Widget build(BuildContext context) {
    final w = WalletService.instance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<double>(
          valueListenable: w.balanceNotifier,
          builder: (_, bal, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today: ₹${w.todayEarning.toStringAsFixed(2)} / ₹${w.dailyCap.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: (w.todayEarning / w.dailyCap).clamp(0, 1)),
                const SizedBox(height: 12),
                Text('Wallet Balance', style: Theme.of(context).textTheme.titleMedium),
                Text('₹${bal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall),
              ],
            );
          },
        ),
      ),
    );
  }
}

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  bool _loadingAd = false;

  Future<void> _showAdAndReward() async {
    setState(() => _loadingAd = true);
    final rewarded = await AdsService.instance.showRewardedAd();
    setState(() => _loadingAd = false);

    if (rewarded) {
      final added = WalletService.instance.addEarningPerAd();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(added ? '₹${WalletService.instance.perAd.toStringAsFixed(2)} added!' : 'Daily cap reached')),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not available right now. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = WalletService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Watch & Earn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Per Ad Reward: ₹${w.perAd.toStringAsFixed(2)}'),
            Text('Daily Cap: ₹${w.dailyCap.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadingAd ? null : _showAdAndReward,
              child: Text(_loadingAd ? 'Loading Ad...' : 'Show Rewarded Ad'),
            ),
            const SizedBox(height: 24),
            const Text('Note: Using AdMob TEST ads here. Replace with your real Ad Unit IDs for production.'),
          ],
        ),
      ),
    );
  }
}

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});
  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _upiController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _mockPayout() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    final ok = WalletService.instance.withdrawAll();
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Mock payout requested!' : 'Nothing to withdraw')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = WalletService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: w.balanceNotifier,
              builder: (_, bal, __) => Text('Current Balance: ₹${bal.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiController,
              decoration: const InputDecoration(
                labelText: 'UPI ID (mock)',
                hintText: 'example@upi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _processing ? null : _mockPayout,
              child: Text(_processing ? 'Processing...' : 'Withdraw All (Mock)'),
            ),
            const SizedBox(height: 12),
            const Text('This screen simulates payout. Connect your real backend for actual UPI payout.'),
          ],
        ),
      ),
    );
  }
}

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = WalletService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Earning Rules')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '- Earn ₹${w.perAd.toStringAsFixed(2)} per rewarded ad.\n'
          '- Daily earning is capped at ₹${w.dailyCap.toStringAsFixed(2)}.\n'
          '- Balance persists on device.\n'
          '- Withdraw is mock for demo; integrate backend for real payouts.\n',
        ),
      ),
    );
  }
}
