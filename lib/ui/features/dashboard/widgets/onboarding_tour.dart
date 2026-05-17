import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// One step of the first-run walkthrough. Pure data — the dialog renders it.
class OnboardingStep {
  const OnboardingStep({required this.titleKey, required this.bodyKey});
  final String titleKey;
  final String bodyKey;
}

const kOnboardingSteps = <OnboardingStep>[
  OnboardingStep(
    titleKey: 'onboarding_welcome_title',
    bodyKey: 'onboarding_welcome_body',
  ),
  OnboardingStep(
    titleKey: 'onboarding_navigation_title',
    bodyKey: 'onboarding_navigation_body',
  ),
  OnboardingStep(
    titleKey: 'onboarding_search_title',
    bodyKey: 'onboarding_search_body',
  ),
  OnboardingStep(
    titleKey: 'onboarding_create_title',
    bodyKey: 'onboarding_create_body',
  ),
  OnboardingStep(
    titleKey: 'onboarding_settings_title',
    bodyKey: 'onboarding_settings_body',
  ),
];

/// Show the first-run walkthrough. Resolves when the user finishes or skips
/// (the caller persists "completed" either way — finishing and skipping are
/// equivalent: the tour should not reappear).
///
/// Non-dismissible by tapping outside so the completion callback always runs
/// through the explicit Skip / Done buttons.
Future<void> showOnboardingTour(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const OnboardingTourDialog(),
  );
}

/// Standalone so it can be widget-tested without the dashboard's `Services`
/// graph. Built from `InTheme` tokens; Skip/Next sit side-by-side per the
/// design-system dialog rule.
class OnboardingTourDialog extends StatefulWidget {
  const OnboardingTourDialog({super.key, this.steps = kOnboardingSteps});

  final List<OnboardingStep> steps;

  @override
  State<OnboardingTourDialog> createState() => _OnboardingTourDialogState();
}

class _OnboardingTourDialogState extends State<OnboardingTourDialog> {
  int _index = 0;

  void _next() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(InSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(step.titleKey),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
              SizedBox(height: InSpacing.md(context)),
              Text(
                context.tr(step.bodyKey),
                style: TextStyle(fontSize: 14, color: tokens.ink2),
              ),
              SizedBox(height: InSpacing.lg(context)),
              Row(
                children: [
                  // Step dots.
                  for (var i = 0; i < widget.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index
                              ? tokens.accent
                              : tokens.border,
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: Text(context.tr('skip')),
                  ),
                  SizedBox(width: InSpacing.md(context)),
                  FilledButton(
                    key: const ValueKey('onboarding_next'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(80, 44),
                    ),
                    onPressed: _next,
                    child: Text(
                      context.tr(isLast ? 'done' : 'next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
