import 'package:flutter/material.dart';

/// Lets code outside the widget tree (widget-tap launch handling) push
/// routes once the app is up, without needing a BuildContext of its own.
final navigatorKey = GlobalKey<NavigatorState>();
