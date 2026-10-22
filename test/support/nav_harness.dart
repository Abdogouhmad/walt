import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt_ui/walt_ui.dart';

/// Hosts [child] inside a [ProviderScope] with the reduce-transparency
/// setting pinned, so the nav tests never touch Hive.
Widget navHost(Widget child, {bool reduceTransparency = false}) =>
    ProviderScope(
      overrides: [
        reduceTransparencyProvider.overrideWithValue(reduceTransparency),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Stack(children: [Positioned.fill(child: child)]),
        ),
      ),
    );

/// The four shell destinations, in shell order.
const List<WaltDestination> shellDestinations = [
  WaltDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  WaltDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    label: 'Activity',
  ),
  WaltDestination(
    icon: Icons.pie_chart_outline,
    selectedIcon: Icons.pie_chart,
    label: 'Budget',
  ),
  WaltDestination(
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    label: 'Reports',
  ),
];

/// The selection pill is the only [Container] drawing an opaque shape; the
/// unselected items and the surrounding chrome all draw transparent.
Finder findSelectionPill() => find
    .byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is ShapeDecoration &&
          ((w.decoration! as ShapeDecoration).color?.a ?? 0) > 0,
    )
    .first;

/// Every item draws a pill [Container] with a [StadiumBorder], in
/// destination order — including the transparent unselected ones, so a
/// collapsed width is readable without comparing two separate pumps.
Finder findPills() => find.descendant(
  of: find.byType(FloatingNavBar),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is ShapeDecoration &&
        (w.decoration! as ShapeDecoration).shape is StadiumBorder,
  ),
);
