import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/data/models/walt_account.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/input_ui.dart';
import 'package:walt/shared/text_ui.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          // start
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icons/wallet.png', height: 100),
              const SizedBox(width: 12),
              const Text(
                "Walt",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // end
          const SizedBox(height: 20),
          UiText(
            text:
                "Your simple, secured, private and beautiful personal finance tracker",
            type: UiTextType.bodyMedium,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          const Spacer(),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: AppButton(
                onPressed: () {
                  onNext();
                },
                size: ButtonSize.large,
                type: ButtonType.iconOnly,
                icon: Icons.navigate_next_rounded,
                iconColor: context.primaryButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityStep extends ConsumerWidget {
  const SecurityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 100, color: Colors.blue),
          const SizedBox(height: 40),
          const Text(
            "Privacy First",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "Protect your financial data with biometric authentication or a passcode.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          SwitchListTile(
            title: const Text("Enable Biometrics"),
            value: settings.isFingerprintEnabled,
            onChanged: (v) => notifier.toggleFingerprint(ref),
          ),
        ],
      ),
    );
  }
}

class SignupStep extends ConsumerStatefulWidget {
  const SignupStep({super.key});

  @override
  ConsumerState<SignupStep> createState() => _SignupStepState();
}

class _SignupStepState extends ConsumerState<SignupStep> {
  final _nameController = TextEditingController();
  String _currency = 'MAD';
  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
      ref
          .read(settingsProvider.notifier)
          .setUserProfile(name: _nameController.text, profilePic: _imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imagePath != null
                    ? FileImage(File(_imagePath!))
                    : null,
                child: _imagePath == null
                    ? const Icon(
                        Icons.add_a_photo_rounded,
                        size: 40,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Setup Your Profile",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            InputUI(
              controller: _nameController,
              labelText: "Full Name",
              hintText: "John Doe",
              icon: Icons.person_outline_rounded,
              onchange: (v) => ref
                  .read(settingsProvider.notifier)
                  .setUserProfile(name: v, profilePic: _imagePath),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: "Default Currency",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              items: [
                'MAD',
                'USD',
                'EUR',
                'GBP',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _currency = v);
                  ref.read(settingsProvider.notifier).setCurrency(v);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AccountStep extends ConsumerStatefulWidget {
  const AccountStep({super.key});

  @override
  ConsumerState<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<AccountStep> {
  final _nameController = TextEditingController(text: 'Cash');
  final _balanceController = TextEditingController(text: '0');
  String _type = 'Cash';

  @override
  void initState() {
    super.initState();
    // Save a default account immediately so they have at least one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveAccount();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    final name = _nameController.text;
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final currency = ref.read(settingsProvider).currency;

    final account = WaltAccount(
      id: 0,
      name: name,
      type: _type,
      balance: balance,
      currency: currency,
      isDefault: true,
    );

    ref.read(accountProvider.notifier).addAccount(account);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.account_balance_wallet_rounded,
                size: 100, color: Colors.green),
            const SizedBox(height: 40),
            const Text(
              "Create Your First Account",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Enter your current balance to start tracking accurately.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),
            InputUI(
              controller: _nameController,
              labelText: "Account Name",
              hintText: "Cash, Bank, etc.",
              icon: Icons.label_outline_rounded,
              onchange: (_) => _saveAccount(),
            ),
            const SizedBox(height: 20),
            InputUI(
              controller: _balanceController,
              labelText: "Initial Balance",
              hintText: "0.00",
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              icon: Icons.account_balance_wallet_outlined,
              onchange: (_) => _saveAccount(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: "Account Type",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                'Cash',
                'Bank',
                'Savings',
                'Credit Card',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _type = v);
                  _saveAccount();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
