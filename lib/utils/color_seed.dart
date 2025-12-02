import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';

const Color primarySeedColor = Color(0xFF1A5F4F); //1A5F4F //177E89
const Color secondarySeedColor = Color(0xFFF4743B);
const Color tertiarySeedColor = Color(0xFF1446A0); //283044
const FlexSchemeVariant flexSchemeVariant = FlexSchemeVariant.soft;

final ColorScheme lightScheme = SeedColorScheme.fromSeeds(
  brightness: Brightness.light,
  primaryKey: primarySeedColor,
  secondaryKey: secondarySeedColor,
  tertiaryKey: tertiarySeedColor,
  variant: flexSchemeVariant,
  // tones: FlexTones.highContrast(Brightness.light),
);

final ColorScheme darkScheme = SeedColorScheme.fromSeeds(
  brightness: Brightness.dark,
  primaryKey: primarySeedColor,
  secondaryKey: secondarySeedColor,
  tertiaryKey: tertiarySeedColor,
  variant: flexSchemeVariant,
  //tones: FlexTones.ultraContrast(Brightness.dark),
);
