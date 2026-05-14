/// Built-in Invoice Ninja design templates.
///
/// Hardcoded fallback for the design pickers so they render before the
/// bundled `data[0].company.designs` payload (the authoritative source of
/// truth, fetched via `/api/v1/login?first_load=true` / `/refresh`) lands in
/// Drift. When the bundle is available, the picker merges these into the
/// dropdown but the bundled rows take precedence on id collision.
///
/// IDs are stable Invoice Ninja design identifiers and must not be changed —
/// the server stores `settings.invoice_design_id` etc. as the literal id.
library;

typedef BuiltInDesign = ({String id, String name, bool isFree});

const kBuiltInDesigns = <BuiltInDesign>[
  // Free templates (admin-portal calls these "Free Designs")
  (id: 'Wpmbk5ezJn', name: 'Plain', isFree: true),
  (id: 'VolejRejNm', name: 'Clean', isFree: true),
  (id: 'Vnalrejny5', name: 'Bold', isFree: true),
  (id: 'Volejvenm9', name: 'Modern', isFree: true),

  // Paid templates
  (id: 'Wpmbk5ezJp', name: 'Business', isFree: false),
  (id: 'Wpmbk5ezJq', name: 'Creative', isFree: false),
  (id: 'Wpmbk5ezJr', name: 'Elegant', isFree: false),
  (id: 'Wpmbk5ezJs', name: 'Hipster', isFree: false),
  (id: 'Wpmbk5ezJt', name: 'Playful', isFree: false),
  (id: 'Wpmbk5ezJu', name: 'Tech', isFree: false),
  (id: 'Wpmbk5ezJv', name: 'Calm', isFree: false),
];

/// Quick id → display name lookup. Populated lazily from [kBuiltInDesigns].
final Map<String, String> kBuiltInDesignNamesById = {
  for (final d in kBuiltInDesigns) d.id: d.name,
};
