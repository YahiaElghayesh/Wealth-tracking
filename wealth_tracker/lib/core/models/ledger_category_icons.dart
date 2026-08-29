/// Sensible default emoji for each built-in quick-pick category — used to
/// backfill [LedgerCategory.icon] on migration/seed so existing users don't
/// see blank chips the first time this becomes user-managed. Once a user
/// picks a different icon in Settings -> Categories & icons, that stored
/// value always wins over this default.
const defaultCategoryEmoji = <String, String>{
  'Groceries': '🛒',
  'Breadfast': '🍞',
  'Talabat': '🍽️',
  'Food Delivery': '🍽️',
  'Food Out': '🍽️',
  'Amazon': '📦',
  'Fuel': '⛽',
  'Electrical': '💡',
  'Gas': '🔥',
  'Telecom': '📱',
  'Pharmacy': '💊',
  'Mother': '👵',
};

/// The picker sheet's options — a broad-enough set to cover most household
/// expense categories without being an unbounded emoji keyboard.
const categoryIconOptions = [
  '🛒', '🛍️', '⛽', '🍽️', '💊', '👪',
  '🏠', '💡', '📱', '🎓', '🎁', '✈️',
  '🚗', '🏥', '🎬', '👕', '🐾', '🏋️',
  '📚', '🧾', '💳', '🔧', '☕', '🎮',
  '🛵', '🥡',
];

const fallbackCategoryEmoji = '🧾';
