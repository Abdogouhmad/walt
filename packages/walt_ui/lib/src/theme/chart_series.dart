import 'dart:math' as math;

import 'package:flutter/material.dart';

import './color_math.dart';

/// Reorders [colors] so the biggest perceptual gap sits between neighbours.
///
/// A pie or donut is read by *adjacency* — the eye compares a wedge to the one
/// touching it, and the list wraps, so the last and first are neighbours too.
/// A greedy walk from a fixed start optimises the first `n - 1` gaps and says
/// nothing about the closing one, so every start is tried and the order with
/// the largest worst-case neighbour gap wins.
List<Color> spreadOutSeries(List<Color> colors) {
  if (colors.length < 3) return List<Color>.unmodifiable(colors);

  List<Color>? best;
  var bestWorstGap = -1.0;

  for (var start = 0; start < colors.length; start++) {
    final remaining = List<Color>.of(colors)..removeAt(start);
    final order = <Color>[colors[start]];
    var worstGap = double.infinity;

    while (remaining.isNotEmpty) {
      final previous = order.last;
      var pick = 0;
      var pickDistance = -1.0;
      for (var i = 0; i < remaining.length; i++) {
        final distance = ColorMath.deltaE(previous, remaining[i]);
        if (distance > pickDistance) {
          pickDistance = distance;
          pick = i;
        }
      }
      worstGap = math.min(worstGap, pickDistance);
      order.add(remaining.removeAt(pick));
    }

    // The list wraps in a donut, so the closing gap counts too — and it is
    // the one gap the greedy walk never got to look at.
    worstGap = math.min(worstGap, ColorMath.deltaE(order.last, order.first));

    if (worstGap > bestWorstGap) {
      bestWorstGap = worstGap;
      best = order;
    }
  }

  return List<Color>.unmodifiable(best!);
}

/// Whether two colour lists hold the same colours in the same order.
bool chartListEquals(List<Color> a, List<Color> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
