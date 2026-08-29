import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/privacy_providers.dart';

/// The visibility toggle for masking money/asset/ledger info — reused as an
/// AppBar action on every tab (not just Net Worth), since the point is
/// being able to hand the phone to someone from wherever you happen to be
/// in the app.
class HideValuesAction extends ConsumerWidget {
  const HideValuesAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    return IconButton(
      icon: Icon(hideValues ? Icons.visibility_off : Icons.visibility),
      tooltip: hideValues ? 'Show values' : 'Hide values',
      onPressed: () => ref.read(hideValuesProvider.notifier).state = !hideValues,
    );
  }
}
