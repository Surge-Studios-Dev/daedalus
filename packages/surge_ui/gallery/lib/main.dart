import 'package:flutter/material.dart';
import 'package:surge_ui/surge_ui.dart';

void main() => runApp(const GalleryApp());

/// The surge_ui gallery: a scrollable catalog of every component, with a theme
/// toggle so each one can be checked in light and dark. This is the human index
/// described in FRAMEWORK.md; the machine index is catalog.json.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'surge_ui gallery',
      debugShowCheckedModeBanner: false,
      theme: buildSurgeTheme(Brightness.light),
      darkTheme: buildSurgeTheme(Brightness.dark),
      themeMode: _mode,
      home: _Gallery(
        mode: _mode,
        onToggleTheme: () => setState(
          () => _mode =
              _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.mode, required this.onToggleTheme});

  final ThemeMode mode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('surge_ui'),
        actions: [
          IconButton(
            icon: Icon(
              mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section('Buttons', _ButtonsDemo()),
          _Section('Inputs', _InputsDemo()),
          _Section('Chips', _ChipsDemo()),
          _Section('Selection', _SelectionDemo()),
          _Section('Rows', _RowsDemo()),
          _Section('Grouped settings', _GroupDemo()),
          _Section('Cards', _CardsDemo()),
          _Section('Badges', _BadgesDemo()),
          _Section('Feedback', _FeedbackDemo()),
          _Section('Magic CTA', _MagicDemo()),
          _Section('Placeholder', _PlaceholderDemo()),
          _Section('Overlays', _OverlaysDemo()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: SurgeText.micro.copyWith(color: t.inkTertiary),
          ),
        ),
        child,
      ],
    );
  }
}

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SurgeButton.primary('Primary', onPressed: () {}),
        SurgeButton.secondary('Secondary', onPressed: () {}),
        SurgeButton.destructive('Delete', onPressed: () {}),
        SurgeButton.ghost('Ghost', onPressed: () {}),
        SurgeButton.small('Small', onPressed: () {}),
        const SurgeButton.primary('Disabled'),
        const SurgeButton.primary('Loading', loading: true),
        SurgeButton.primary('With icon', icon: Icons.bolt, onPressed: () {}),
        SurgeIconButton(icon: Icons.favorite, accent: true, onPressed: () {}),
      ],
    );
  }
}

class _InputsDemo extends StatelessWidget {
  const _InputsDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SurgeTextField(placeholder: 'Email address'),
        SizedBox(height: 12),
        SurgeTextField(
          placeholder: 'Password',
          obscureText: true,
          showVisibilityToggle: true,
        ),
        SizedBox(height: 12),
        SurgeTextField(placeholder: 'This field has an error', error: true),
        SizedBox(height: 12),
        SurgeSearchField(),
      ],
    );
  }
}

class _RowsDemo extends StatelessWidget {
  const _RowsDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SurgeListRow(
          title: 'List row with tile',
          sub: 'Supporting subtitle',
          iconTile: Icons.person,
          chevron: true,
        ),
        SurgeListRow(title: 'Plain row', icon: Icons.link, chevron: true),
        SurgeListRow(title: 'Destructive row', icon: Icons.delete, danger: true),
      ],
    );
  }
}

class _GroupDemo extends StatelessWidget {
  const _GroupDemo();

  @override
  Widget build(BuildContext context) {
    return const SurgeGroupSection(
      header: 'Preferences',
      footer: 'Grouped rows with a header and footer.',
      children: [
        SurgeGroupRow(
          title: 'Notifications',
          icon: Icons.notifications,
          toggle: true,
        ),
        SurgeGroupRow(title: 'Appearance', value: 'System', chevron: true),
        SurgeGroupRow(title: 'Sign out', danger: true),
      ],
    );
  }
}

class _CardsDemo extends StatelessWidget {
  const _CardsDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SurgeActionCard(
          icon: Icons.star,
          title: 'Selected option',
          sub: 'Accent border and check',
          selected: true,
        ),
        SizedBox(height: 12),
        SurgeActionCard(
          icon: Icons.tune,
          title: 'Unselected option',
          sub: 'Tap to choose',
        ),
        SizedBox(height: 12),
        SurgeCard(
          elevated: true,
          child: Text('A plain elevated SurgeCard holding arbitrary content.'),
        ),
      ],
    );
  }
}

class _ChipsDemo extends StatefulWidget {
  const _ChipsDemo();
  @override
  State<_ChipsDemo> createState() => _ChipsDemoState();
}

class _ChipsDemoState extends State<_ChipsDemo> {
  final _on = <String>{'All'};

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in ['All', 'Recent', 'Favorites'])
          SurgeFilterChip(
            label: f,
            selected: _on.contains(f),
            onPressed: () => setState(
              () => _on.contains(f) ? _on.remove(f) : _on.add(f),
            ),
          ),
        SurgeTagChip(label: 'Removable', onRemove: () {}),
        const SurgeTagChip(label: 'Icon tag', icon: Icons.tag),
      ],
    );
  }
}

class _SelectionDemo extends StatefulWidget {
  const _SelectionDemo();
  @override
  State<_SelectionDemo> createState() => _SelectionDemoState();
}

class _SelectionDemoState extends State<_SelectionDemo> {
  bool _toggle = true;
  String _seg = 'Light';
  double _count = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SurgeToggle(on: _toggle, onChanged: (v) => setState(() => _toggle = v)),
            const SizedBox(width: 16),
            SurgeStepper(
              value: _count,
              onChanged: (v) => setState(() => _count = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SurgeSegmented(
          options: const ['System', 'Light', 'Dark'],
          value: _seg,
          onChanged: (v) => setState(() => _seg = v),
        ),
      ],
    );
  }
}

class _FeedbackDemo extends StatelessWidget {
  const _FeedbackDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SurgeBanner(
          message: 'A neutral inline banner.',
          icon: Icons.info_outline,
        ),
        SizedBox(height: 8),
        SurgeBanner(
          message: 'Something needs attention.',
          kind: SurgeBannerKind.warning,
          icon: Icons.warning_amber,
        ),
        SizedBox(height: 16),
        SurgeProgressBar(value: 0.6),
        SizedBox(height: 12),
        SurgeIndeterminateBar(),
        SizedBox(height: 16),
        Row(
          children: [
            SurgeSpinner(),
            SizedBox(width: 16),
            Expanded(child: SurgeSkeleton()),
          ],
        ),
        SizedBox(height: 8),
        SurgeLoadingLabel('Loading'),
        SurgeEmptyState(
          icon: Icons.inbox,
          title: 'Nothing here yet',
          sub: 'Empty states, zero-results, and errors all use this.',
        ),
      ],
    );
  }
}

class _BadgesDemo extends StatelessWidget {
  const _BadgesDemo();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SurgeBadge('New'),
        SurgeBadge('Pro', icon: Icons.auto_awesome),
        SurgeBadge('Saved', kind: SurgeBadgeKind.success),
        SurgeBadge('Beta', kind: SurgeBadgeKind.warning),
        SurgeBadge('Off', kind: SurgeBadgeKind.neutral),
      ],
    );
  }
}

class _MagicDemo extends StatelessWidget {
  const _MagicDemo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SurgeMagicCta(label: 'Auto-plan my week', onTap: () {}),
    );
  }
}

class _PlaceholderDemo extends StatelessWidget {
  const _PlaceholderDemo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SurgeRadii.md),
      child: const SizedBox(
        height: 120,
        width: double.infinity,
        child: SurgePlaceholder(label: 'no image', big: true),
      ),
    );
  }
}

class _OverlaysDemo extends StatelessWidget {
  const _OverlaysDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SurgeButton.secondary(
          'Show sheet',
          onPressed: () => showSurgeSheet(
            context,
            builder: (_) => const SurgeSheet(
              title: 'A sheet',
              body: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text('Bottom-sheet content goes here.'),
              ),
            ),
          ),
        ),
        SurgeButton.secondary(
          'Confirm',
          onPressed: () => showSurgeConfirm(
            context,
            title: 'Delete this?',
            body: 'This cannot be undone.',
            confirmLabel: 'Delete',
            destructive: true,
          ),
        ),
        SurgeButton.secondary(
          'Toast',
          onPressed: () => showSurgeToast(
            context,
            message: 'Saved',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
        SurgeButton.secondary(
          'Action menu',
          onPressed: () => showSurgeActionMenu(
            context,
            title: 'Recipe',
            items: [
              const SurgeActionMenuItem(icon: Icons.share, label: 'Share'),
              const SurgeActionMenuItem(
                icon: Icons.star,
                label: 'Favorite',
                badge: 'PRO',
              ),
              const SurgeActionMenuItem(
                icon: Icons.delete,
                label: 'Delete',
                danger: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
