import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether monetary values are currently masked app-wide — toggled from the
/// Dashboard's app bar so the user can hand their phone to someone without
/// showing every balance. Deliberately in-memory only (not persisted): it
/// always starts back at "visible" on a fresh app launch rather than
/// silently staying hidden (or shown) from a previous session.
final hideValuesProvider = StateProvider<bool>((ref) => false);
