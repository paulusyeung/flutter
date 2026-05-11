import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/services.dart';
import '../view_models/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = LoginViewModel(auth: context.read<Services>().auth);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) => _LoginForm(vm: _vm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.vm});
  final LoginViewModel vm;

  Future<void> _onSubmit(BuildContext context) async {
    final ok = await vm.submit();
    if (!context.mounted) return;
    if (ok) {
      // The router's `redirect` watches AuthRepository.credentials and pushes
      // us into the shell automatically. No imperative navigation needed.
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error!)),
      );
    }
  }

  Future<void> _onRecover(BuildContext context) async {
    final ok = await vm.recover();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Check your email for a reset link.' : (vm.error ?? 'Failed'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Invoice Ninja',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Hosted')),
            ButtonSegment(value: false, label: Text('Self-hosted')),
          ],
          selected: {vm.isHosted},
          onSelectionChanged: (s) => vm.setHosted(s.first),
        ),
        const SizedBox(height: 16),
        if (!vm.isHosted) ...[
          TextField(
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://invoicing.example.com',
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: vm.setUrlOverride,
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: vm.fieldErrors['email']?.first,
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onChanged: vm.setEmail,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: vm.fieldErrors['password']?.first,
          ),
          obscureText: true,
          onChanged: vm.setPassword,
          onSubmitted: vm.busy ? null : (_) => _onSubmit(context),
        ),
        if (vm.requiresOtp) ...[
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'One-time password',
              hintText: '6-digit code',
            ),
            keyboardType: TextInputType.number,
            onChanged: vm.setOneTimePassword,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: vm.busy ? null : () => _onSubmit(context),
          child: vm.busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign in'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: vm.busy ? null : () => _onRecover(context),
          child: const Text('Forgot password?'),
        ),
      ],
    );
  }
}
