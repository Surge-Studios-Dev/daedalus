/// Surge Studios shared UI toolbox.
///
/// The token contract, theme builder, and presentational component library that
/// every Surge app composes from (Tier 2 in `FRAMEWORK.md`). Components depend
/// only on [SurgeTokens]; they carry no domain logic and no state management.
///
/// ```dart
/// import 'package:surge_ui/surge_ui.dart';
///
/// MaterialApp(
///   theme: buildSurgeTheme(Brightness.light),
///   darkTheme: buildSurgeTheme(Brightness.dark),
///   home: Scaffold(
///     body: Center(child: SurgeButton.primary('Get started', onPressed: () {})),
///   ),
/// );
/// ```
library;

// Tokens + theme (the contract everything else is built against).
export 'src/tokens/surge_tokens.dart';
export 'src/tokens/surge_text.dart';
export 'src/theme/surge_theme.dart';

// Catalog metadata.
export 'src/catalog/component_meta.dart';

// Components (Tier 2).
export 'src/components/surge_pressable.dart';
export 'src/components/surge_button.dart';
export 'src/components/surge_text_field.dart';
export 'src/components/surge_list_row.dart';
export 'src/components/surge_card.dart';
export 'src/components/surge_chip.dart';
export 'src/components/surge_badge.dart';
export 'src/components/surge_toggle.dart';
export 'src/components/surge_spinner.dart';
export 'src/components/surge_segmented.dart';
export 'src/components/surge_stepper.dart';
export 'src/components/surge_banner.dart';
export 'src/components/surge_progress.dart';
export 'src/components/surge_empty_state.dart';
export 'src/components/surge_loading_label.dart';
export 'src/components/surge_placeholder.dart';
export 'src/components/surge_magic_cta.dart';
export 'src/components/surge_sheet.dart';
export 'src/components/surge_toast.dart';
