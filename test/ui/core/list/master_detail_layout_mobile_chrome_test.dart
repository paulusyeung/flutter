// Regression test for the master-detail pane's viewport-aware chrome
// (`lib/ui/core/list/master_detail_layout.dart`, `_PaneRoot`).
//
// On a NARROW viewport (`< Breakpoints.slideOver == 1024`) the pane renders
// full-page, so the chrome is a mobile-standard leading back arrow — NOT the
// desktop trailing full-screen-toggle + X. On WIDE the pane floats as a
// slide-over and keeps the trailing toggle + X. The bug this guards: the
// desktop chrome (and a `_PaneRoot` with no `Material` ancestor) leaked onto
// mobile, showing an X + full-screen toggle and painting "missing Material"
// yellow underlines.

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../_localization_helper.dart';

/// Minimal Services stub — the chrome path doesn't touch it, but a provider is
/// supplied so any incidental `context.read<Services>()` can't throw.
class _FakeServices implements Services {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Pane body that surfaces BOTH chrome slots published by `_PaneRoot`, so the
/// test can assert which one is present at a given viewport.
class _PaneBody extends StatelessWidget {
  const _PaneBody(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final leading = MasterDetailPaneScope.paneLeadingOf(context);
    final actions = MasterDetailPaneScope.paneActionsOf(context);
    return Scaffold(
      body: Column(
        children: [
          if (leading != null) leading,
          if (actions != null) actions,
          Text(label),
        ],
      ),
    );
  }
}

/// Pane body with NO Scaffold of its own — mirrors the real embedded detail
/// body (`EntityDetailScaffold` in embedded mode renders no Scaffold). Reports
/// whether it has an ancestor `Material`. Without the narrow branch's `Material`
/// wrapper this resolves to NO_MATERIAL, which is exactly what made the
/// plain-Container cards paint the "missing Material" yellow underlines.
class _MaterialProbeBody extends StatelessWidget {
  const _MaterialProbeBody();
  @override
  Widget build(BuildContext context) {
    final hasMaterial =
        context.findAncestorWidgetOfExactType<Material>() != null;
    return Text(hasMaterial ? 'HAS_MATERIAL' : 'NO_MATERIAL');
  }
}

void main() {
  String currentUri(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required Size size,
    Widget detail = const _PaneBody('DETAIL'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) => NoTransitionPage<void>(
            key: const ValueKey('master_detail:/products'),
            child: Builder(
              builder: (ctx) {
                final hasPane = state.matchedLocation != '/products';
                return MasterDetailLayout(
                  basePath: '/products',
                  list: const Scaffold(body: Center(child: Text('LIST'))),
                  rightPane: hasPane ? child : null,
                  viewMode: state.uri.queryParameters['view'],
                );
              },
            ),
          ),
          routes: [
            GoRoute(
              path: '/products',
              builder: (_, _) => const SizedBox.shrink(),
            ),
            GoRoute(path: '/products/:id', builder: (_, _) => detail),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      Provider<Services>.value(
        value: _FakeServices(),
        child: MaterialApp.router(
          theme: buildInTheme(InTheme.light),
          localizationsDelegates: kTestLocalizationsDelegates,
          supportedLocales: kTestSupportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('narrow viewport: detail pane shows a leading back arrow, no X / '
      'full-screen toggle; tapping it returns to the list', (tester) async {
    final router = await pumpApp(tester, size: const Size(800, 900));

    router.go('/products/1');
    await tester.pumpAndSettle();
    expect(find.text('DETAIL'), findsOneWidget);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    // Desktop pane chrome must be absent on narrow.
    expect(find.byTooltip('Close'), findsNothing);
    expect(find.byIcon(Icons.open_in_full), findsNothing);
    expect(find.byIcon(Icons.close_fullscreen), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(currentUri(router), '/products');
    expect(find.text('DETAIL'), findsNothing);
  });

  testWidgets(
    'narrow viewport: the full-page pane has a Material ancestor (fixes the '
    '"missing Material" yellow underlines on plain-Container cards)',
    (tester) async {
      final router = await pumpApp(
        tester,
        size: const Size(800, 900),
        detail: const _MaterialProbeBody(),
      );

      router.go('/products/1');
      await tester.pumpAndSettle();

      expect(find.text('HAS_MATERIAL'), findsOneWidget);
      expect(find.text('NO_MATERIAL'), findsNothing);
    },
  );

  testWidgets(
    'wide viewport: detail pane keeps the trailing full-screen toggle + X, '
    'no back arrow',
    (tester) async {
      final router = await pumpApp(tester, size: const Size(1600, 900));

      router.go('/products/1');
      await tester.pumpAndSettle();
      expect(find.text('DETAIL'), findsOneWidget);

      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    },
  );
}
