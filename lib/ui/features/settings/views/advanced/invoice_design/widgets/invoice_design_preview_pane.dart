import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/services/live_design_service.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/widgets/live_pdf_preview_pane.dart';

/// Persistent live PDF preview pane for the Invoice Design shell.
///
/// Hoisted out of the General Settings tab so the preview survives tab
/// switches — it now lives beside the `TabBarView` at the shell level (see
/// [CascadeTabbedSettingsShell.sidePane]). Reads [SettingsDraftHost] /
/// [SettingsLevelController] off the existing Provider scope (the shell
/// provides them via `SettingsCompanyScopedHost` / `SettingsPageScaffold`),
/// so it edits-and-previews the same cascade VM every tab is bound to — no
/// re-providing.
///
/// Renders against a `surfaceAlt` background so it reads as a distinct panel
/// against the form's `surface`; the upstream `VerticalDivider` is the only
/// boundary chrome. No in-pane Save button — the shell's own
/// `SettingsPageScaffold` save action covers every tab.
class InvoiceDesignPreviewPane extends StatefulWidget {
  const InvoiceDesignPreviewPane({super.key, required this.companyId});

  final String companyId;

  @override
  State<InvoiceDesignPreviewPane> createState() =>
      _InvoiceDesignPreviewPaneState();
}

class _InvoiceDesignPreviewPaneState extends State<InvoiceDesignPreviewPane> {
  late final LiveDesignService _service;
  late final Stream<Company?> _companyStream;

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    _service = LiveDesignService(services.apiClient);
    // Cache the company stream so every parent rebuild doesn't trigger a
    // fresh `watchCompany(...)` call (Drift returns a new stream instance
    // per call). The bitmask only changes when the company row updates,
    // which is rare — the stream stays alive for the screen's lifetime.
    _companyStream = services.company.watchCompany(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return ColoredBox(
      color: tokens.surfaceAlt,
      child: StreamBuilder<Company?>(
        stream: _companyStream,
        builder: (context, snapshot) {
          return LivePdfPreviewPane(
            service: _service,
            enabledModulesBitmask: snapshot.data?.enabledModules ?? 0,
            embedded: true,
          );
        },
      ),
    );
  }
}

/// Fullscreen-dialog host for the live PDF preview, pushed on phone widths
/// where there's no room for the persistent side pane. The shell triggers
/// the push from a context that still has the cascade providers in scope;
/// this screen re-provides the captured [host] / [level] because it's
/// mounted under the Navigator root, outside the settings provider subtree.
class InvoiceDesignPreviewScreen extends StatelessWidget {
  const InvoiceDesignPreviewScreen({
    super.key,
    required this.host,
    required this.level,
    required this.service,
    required this.companyId,
  });

  final SettingsDraftHost host;
  final SettingsLevelController level;
  final LiveDesignService service;
  final String? companyId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsDraftHost>.value(value: host),
        ChangeNotifierProvider<SettingsLevelController>.value(value: level),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('preview'))),
        body: companyId == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<Company?>(
                stream: services.company.watchCompany(companyId!),
                builder: (context, snapshot) {
                  return LivePdfPreviewPane(
                    service: service,
                    enabledModulesBitmask: snapshot.data?.enabledModules ?? 0,
                  );
                },
              ),
      ),
    );
  }
}
