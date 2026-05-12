import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';

import '../../../_localization_helper.dart';

/// Verifies the per-slot gating and label resolution that drive the
/// custom-fields section on edit screens.

Widget _wrap(Widget child) {
  // EntityEditField reads `context.inTheme` via the `InThemeContext`
  // extension; without an `InTheme` ThemeExtension installed the
  // extension returns null and the bang-operator inside the field's build
  // throws. Mirrors the wiring `lib/app/theme.dart` does in production.
  final theme = ThemeData.light().copyWith(
    extensions: <ThemeExtension<dynamic>>[InTheme.light],
  );
  return MaterialApp(
    theme: theme,
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('EntityCustomFieldsSection', () {
    testWidgets('renders nothing when no slots are configured', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EntityCustomFieldsSection(
            keyPrefix: 'client',
            companyStream: Stream<Company?>.value(
              const Company(id: 'co', name: 'Acme'),
            ),
            values: const ['', '', '', ''],
            onChanged: List.generate(4, (_) => (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EntityEditField), findsNothing);
    });

    testWidgets(
      'renders only the configured slots, in slot order, with the parsed labels',
      (tester) async {
        // Slots 1 and 3 have labels; 2 and 4 are empty. Expect exactly two
        // EntityEditFields with labels "Region" and "Project", in order.
        await tester.pumpWidget(
          _wrap(
            EntityCustomFieldsSection(
              keyPrefix: 'client',
              companyStream: Stream<Company?>.value(
                const Company(
                  id: 'co',
                  name: 'Acme',
                  customFields: {
                    'client1': 'Region|North,South',
                    'client3': 'Project',
                  },
                ),
              ),
              values: const ['existingRegion', '', 'existingProject', ''],
              onChanged: List.generate(4, (_) => (_) {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(EntityEditField);
        expect(fields, findsNWidgets(2));
        expect(find.text('Region'), findsOneWidget);
        expect(find.text('Project'), findsOneWidget);
        // Pre-seeded values render too.
        expect(find.text('existingRegion'), findsOneWidget);
        expect(find.text('existingProject'), findsOneWidget);
      },
    );

    testWidgets(
      'uses the parsed label half when the value carries `Label|presets`',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            EntityCustomFieldsSection(
              keyPrefix: 'product',
              companyStream: Stream<Company?>.value(
                const Company(
                  id: 'co',
                  name: 'Acme',
                  customFields: {'product1': 'SKU|alpha,beta'},
                ),
              ),
              values: const ['', '', '', ''],
              onChanged: List.generate(4, (_) => (_) {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('SKU'), findsOneWidget);
        expect(find.textContaining('alpha'), findsNothing);
      },
    );

    testWidgets('wires each onChanged callback to its corresponding slot', (
      tester,
    ) async {
      final receivedSlot1 = <String>[];
      final receivedSlot3 = <String>[];
      await tester.pumpWidget(
        _wrap(
          EntityCustomFieldsSection(
            keyPrefix: 'client',
            companyStream: Stream<Company?>.value(
              const Company(
                id: 'co',
                name: 'Acme',
                customFields: {'client1': 'Region', 'client3': 'Project'},
              ),
            ),
            values: const ['', '', '', ''],
            onChanged: [receivedSlot1.add, (_) {}, receivedSlot3.add, (_) {}],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'east');
      await tester.enterText(find.byType(TextField).last, 'launch');
      await tester.pump();
      expect(receivedSlot1.last, 'east');
      expect(receivedSlot3.last, 'launch');
    });

    testWidgets(
      'renders nothing while the stream is in flight (no Company emitted yet)',
      (tester) async {
        // Cold stream that never emits — mirrors the first frame after
        // login when the Company subscription is still warming up. Section
        // should be silently absent rather than showing four blank slots.
        final controller = StreamController<Company?>();
        addTearDown(controller.close);
        await tester.pumpWidget(
          _wrap(
            EntityCustomFieldsSection(
              keyPrefix: 'client',
              companyStream: controller.stream,
              values: const ['', '', '', ''],
              onChanged: List.generate(4, (_) => (_) {}),
            ),
          ),
        );
        expect(find.byType(EntityEditField), findsNothing);
      },
    );
  });
}
