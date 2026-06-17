// Branch + toast cover for the shared bulk Download / Print PDF handlers.
//
// The `printing` plugin can't run under flutter_test, so these exercise the
// routing (count==1 vs >1; which injected closure fires) and the user-facing
// toasts WITHOUT reaching `Printing.sharePdf` / `Printing.layoutPdf` — every
// case errors or branches before the platform call.

import 'dart:async';
import 'dart:typed_data';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/toast_controller.dart';
import 'package:admin/ui/core/widgets/toast_host.dart';
import 'package:admin/ui/features/billing_shared/actions/billing_doc_bulk_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../_localization_helper.dart';

// Toasts now render through the global ToastHost reading a `ToastController`.
// Provide one directly (Notify prefers a provided controller over Services)
// and mount the host so the `find.text(...)` assertions see the toast.
Widget _host(ToastController toasts, void Function(BuildContext) onPressed) =>
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      // `.value` so the provider doesn't dispose our controller; ChangeNotifier
      // subtype requires ChangeNotifierProvider (plain Provider asserts).
      home: ChangeNotifierProvider<ToastController>.value(
        value: toasts,
        child: Stack(
          children: [
            Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => onPressed(context),
                    child: const Text('go'),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: ToastHost(controller: toasts)),
          ],
        ),
      ),
    );

void main() {
  group('bulkDownloadBillingDocs', () {
    testWidgets('count > 1 fires the async server export and toasts '
        'exported_data (no single-fetch)', (tester) async {
      var bulkCalled = 0;
      var singleCalled = 0;
      final toasts = ToastController();
      await tester.pumpWidget(
        _host(
          toasts,
          (c) => bulkDownloadBillingDocs(
            c,
            count: 3,
            bulkDownload: () async => bulkCalled++,
            singleFetch: () async {
              singleCalled++;
              return Uint8List(0);
            },
            singleFileName: 'x.pdf',
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(bulkCalled, 1);
      expect(singleCalled, 0, reason: 'multi-doc path must not single-fetch');
      // exported_data: "...you'll receive an email with a download link"
      expect(find.textContaining('email'), findsOneWidget);
      toasts.clearAll();
      await tester.pumpAndSettle();
    });

    testWidgets('count > 1 export failure toasts an_error_occurred', (
      tester,
    ) async {
      final toasts = ToastController();
      await tester.pumpWidget(
        _host(
          toasts,
          (c) => bulkDownloadBillingDocs(
            c,
            count: 2,
            bulkDownload: () async => throw Exception('boom'),
            singleFetch: () async => Uint8List(0),
            singleFileName: 'x.pdf',
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('An error occurred'), findsOneWidget);
      toasts.clearAll();
      await tester.pumpAndSettle();
    });

    testWidgets('count == 1 routes to the single-doc path, not the server '
        'export', (tester) async {
      var bulkCalled = 0;
      var singleCalled = 0;
      final toasts = ToastController();
      await tester.pumpWidget(
        _host(
          toasts,
          (c) => bulkDownloadBillingDocs(
            c,
            count: 1,
            bulkDownload: () async => bulkCalled++,
            // Throw a sentinel *after* recording so the routing is proven
            // without invoking Printing.sharePdf under test.
            singleFetch: () async {
              singleCalled++;
              throw Exception('stop-before-share');
            },
            singleFileName: 'one.pdf',
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(singleCalled, 1, reason: 'count==1 routes to singleFetch');
      expect(bulkCalled, 0, reason: 'count==1 must not hit the server export');
      // The sentinel throw surfaces an error toast — cancel its timer.
      toasts.clearAll();
      await tester.pumpAndSettle();
    });
  });

  group('bulkPrintBillingDocs', () {
    testWidgets('shows Processing up front, then errors if the merge fails', (
      tester,
    ) async {
      final gate = Completer<Uint8List>();
      final toasts = ToastController();
      await tester.pumpWidget(
        _host(toasts, (c) => bulkPrintBillingDocs(c, fetch: () => gate.future)),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle(); // slide the "Processing" toast in

      expect(find.text('Processing'), findsOneWidget);

      gate.completeError(Exception('merge failed'));
      await tester.pumpAndSettle();

      expect(
        find.text('Processing'),
        findsNothing,
        reason: 'replaced on error',
      );
      expect(find.text('Error'), findsOneWidget);
      toasts.clearAll();
      await tester.pumpAndSettle();
    });
  });
}
