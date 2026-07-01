/// Machine-readable description of a shared component, attached to its public
/// widget class. It powers the catalog (the searchable index in
/// `catalog.json`) and, later, generation of that index straight from source.
///
/// Keep every field in sync with the widget: [name] matches the class,
/// [variants] lists the named constructors / style enums, [whenToUse] is the
/// one line that decides whether someone reaches for this vs. writing custom.
class SurgeComponent {
  const SurgeComponent({
    required this.name,
    required this.category,
    required this.summary,
    required this.whenToUse,
    this.variants = const [],
    this.tags = const [],
    this.since = '0.1.0',
  });

  /// Public class name, e.g. `SurgeButton`.
  final String name;

  /// Grouping used in the gallery and catalog: buttons, inputs, rows, cards,
  /// feedback, layout, navigation, media.
  final String category;

  /// One sentence: what it renders.
  final String summary;

  /// One sentence: when to choose this over an alternative or custom code.
  final String whenToUse;

  /// Named constructors or style variants, e.g. `['primary', 'ghost']`.
  final List<String> variants;

  /// Free-text search keywords.
  final List<String> tags;

  /// Version the component was introduced in.
  final String since;
}
