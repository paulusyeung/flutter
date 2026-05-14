import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/auth/view_models/login_view_model.dart';

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
      backgroundColor: context.inTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: InSpacing.xl,
              vertical: InSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) => _LoginBody(vm: _vm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody({required this.vm});

  final LoginViewModel vm;

  String? _resolveError(BuildContext context) {
    if (vm.errorKey != null) return context.tr(vm.errorKey!, vm.errorParams);
    return vm.errorMessage;
  }

  Future<void> _onEmailSubmit(BuildContext context) async {
    final ok = await vm.submit();
    if (!context.mounted) return;
    final msg = _resolveError(context);
    if (!ok && msg != null) {
      Notify.error(context, msg);
    }
  }

  Future<void> _onAppleSubmit(BuildContext context) async {
    final ok = await vm.submitApple();
    if (!context.mounted) return;
    final msg = _resolveError(context);
    if (!ok && msg != null) {
      Notify.error(context, msg);
    }
  }

  Future<void> _onRecover(BuildContext context) async {
    final ok = await vm.recover();
    if (!context.mounted) return;
    if (ok) {
      Notify.success(context, context.tr('password_reset_link_sent'));
    } else {
      Notify.error(context, _resolveError(context) ?? context.tr('failed'));
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          isDark
              ? 'assets/images/logo_dark.png'
              : 'assets/images/logo_light.png',
          height: 48,
        ),
        const SizedBox(height: InSpacing.xl),
        _SurfaceCard(
          shadow: tokens.shadow2,
          padding: const EdgeInsets.all(InSpacing.xl),
          child: _LoginForm(
            vm: vm,
            onEmailSubmit: () => _onEmailSubmit(context),
            onAppleSubmit: () => _onAppleSubmit(context),
            onSignup: () => _openExternal(kSignupUrl),
          ),
        ),
        SizedBox(height: InSpacing.md(context)),
        _SurfaceCard(
          shadow: tokens.shadow1,
          padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
          child: _RecoverStatusActions(
            onRecover: vm.busy ? null : () => _onRecover(context),
            onStatus: () => _openExternal(kStatusUrl),
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.vm,
    required this.onEmailSubmit,
    required this.onAppleSubmit,
    required this.onSignup,
  });

  final LoginViewModel vm;
  final VoidCallback onEmailSubmit;
  final VoidCallback onAppleSubmit;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    final isApple = vm.method == LoginMethod.apple;
    final tokens = context.inTheme;
    // Wrap the form in AutofillGroup so the OS / password manager treats the
    // email + password (+ OTP) as a connected login form and offers to save
    // / fill them together. Without this, the hints below still work but the
    // pair isn't correlated, so "save password" prompts don't fire.
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EyebrowLabel(context.tr('select_platform').toUpperCase()),
          _SegmentedToggle<bool>(
            value: vm.isHosted,
            segments: [
              _Segment(value: true, label: context.tr('hosted')),
              _Segment(value: false, label: context.tr('self_hosted')),
            ],
            onChanged: vm.setHosted,
          ),
          if (vm.isHosted) ...[
            SizedBox(height: InSpacing.lg(context)),
            _EyebrowLabel(context.tr('select_method').toUpperCase()),
            _SegmentedToggle<LoginMethod>(
              value: vm.method,
              segments: [
                _Segment(value: LoginMethod.email, label: context.tr('email')),
                _Segment(value: LoginMethod.apple, label: context.tr('apple')),
              ],
              onChanged: vm.setMethod,
            ),
          ],
          SizedBox(height: InSpacing.lg(context)),
          if (!vm.isHosted) ...[
            _InField(
              label: context.tr('server_url'),
              hint: 'https://invoicing.example.com',
              keyboardType: TextInputType.url,
              autofillHints: const [AutofillHints.url],
              onChanged: vm.setUrlOverride,
            ),
            SizedBox(height: InSpacing.md(context)),
          ],
          if (!isApple) ...[
            _InField(
              label: context.tr('email'),
              initialValue: vm.email,
              keyboardType: TextInputType.emailAddress,
              errorText: vm.fieldErrors['email']?.first,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              onChanged: vm.setEmail,
            ),
            SizedBox(height: InSpacing.md(context)),
            _PasswordField(
              label: context.tr('password'),
              initialValue: vm.password,
              errorText: vm.fieldErrors['password']?.first,
              onChanged: vm.setPassword,
              onSubmitted: vm.busy ? null : (_) => onEmailSubmit(),
            ),
            SizedBox(height: InSpacing.md(context)),
            _InField(
              label: context.tr('two_factor_otp_optional'),
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              onChanged: vm.setOneTimePassword,
            ),
          ],
          const SizedBox(height: InSpacing.xl),
          FilledButton.icon(
            key: const ValueKey('login_submit'),
            onPressed: vm.busy
                ? null
                : (isApple ? onAppleSubmit : onEmailSubmit),
            icon: vm.busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        // Spinner matches the button's foreground.
                        isApple ? tokens.surface : Colors.white,
                      ),
                    ),
                  )
                : Icon(isApple ? Icons.apple : Icons.mail_outline, size: 18),
            label: Text(
              isApple
                  ? context.tr('sign_in_with_apple')
                  : context.tr('login_with_email'),
            ),
            style: FilledButton.styleFrom(
              // Apple HIG: black-on-light, white-on-dark. `ink` already
              // inverts with brightness, so the button flips for free.
              backgroundColor: isApple ? tokens.ink : tokens.accent,
              foregroundColor: isApple ? tokens.surface : Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InRadii.r2),
              ),
            ),
          ),
          const SizedBox(height: InSpacing.sm),
          TextButton(
            onPressed: onSignup,
            child: Text(context.tr('create_your_account')),
          ),
        ],
      ),
    );
  }
}

// ─── Recover / Status actions ────────────────────────────────────────────

class _RecoverStatusActions extends StatelessWidget {
  const _RecoverStatusActions({
    required this.onRecover,
    required this.onStatus,
  });

  final VoidCallback? onRecover;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    final recover = TextButton.icon(
      onPressed: onRecover,
      icon: const Icon(Icons.lock_outline, size: 16),
      label: Text(context.tr('recover_password')),
    );
    final status = TextButton.icon(
      onPressed: onStatus,
      icon: const Icon(Icons.shield_outlined, size: 16),
      label: Text(context.tr('check_status')),
    );
    if (Breakpoints.isGlobalNavVisible(context)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [recover, status],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [recover, status],
    );
  }
}

// ─── Surface card ────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    required this.padding,
    required this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
        boxShadow: shadow,
      ),
      padding: padding,
      child: child,
    );
  }
}

// ─── Eyebrow section label ───────────────────────────────────────────────

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: InSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: context.inTheme.ink3,
        ),
      ),
    );
  }
}

// ─── Segmented toggle ────────────────────────────────────────────────────

class _Segment<T> {
  const _Segment({required this.value, required this.label});
  final T value;
  final String label;
}

class _SegmentedToggle<T> extends StatelessWidget {
  const _SegmentedToggle({
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  final T value;
  final List<_Segment<T>> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(InRadii.r2),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: _SegmentButton(
                label: s.label,
                selected: s.value == value,
                onTap: () => onChanged(s.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(InRadii.r1),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tokens.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(InRadii.r1),
            border: Border.all(
              color: selected ? tokens.borderStrong : Colors.transparent,
            ),
            boxShadow: selected ? tokens.shadow1 : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? tokens.ink : tokens.ink3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Field with above-the-field label (v2 convention) ──────────────────

class _InField extends StatefulWidget {
  const _InField({
    required this.label,
    this.hint,
    this.initialValue,
    this.keyboardType,
    this.errorText,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.autofillHints,
  });

  final String label;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final String? errorText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  @override
  State<_InField> createState() => _InFieldState();
}

class _InFieldState extends State<_InField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.inTheme.ink3,
            ),
          ),
        ),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            suffixIcon: widget.suffix,
          ),
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          autocorrect: !widget.obscureText,
          enableSuggestions: !widget.obscureText,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return _InField(
      label: widget.label,
      initialValue: widget.initialValue,
      errorText: widget.errorText,
      obscureText: _obscured,
      autofillHints: const [AutofillHints.password],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        tooltip: _obscured
            ? context.tr('show_password')
            : context.tr('hide_password'),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 18,
          color: context.inTheme.ink3,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    );
  }
}
