import 'package:flutter/material.dart';

import 'pawmilya_palette.dart';

ThemeData buildPawmilyaTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: PawmilyaPalette.gold),
    scaffoldBackgroundColor: PawmilyaPalette.creamTop,
    useMaterial3: true,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: PawmilyaPalette.textPrimary,
      displayColor: PawmilyaPalette.textPrimary,
    ),
  );
}
