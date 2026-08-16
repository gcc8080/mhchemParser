import 'package:flutter/widgets.dart';
import 'package:mhchem_parser/mhchem_parser.dart';

void main() {
  final output = MhchemParser.convert('H2O', mode: MhchemMode.ce);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text(output)),
    ),
  );
}
