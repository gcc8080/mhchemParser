import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mhchem_parser/mhchem_parser.dart';

void main() {
  testWidgets('Flutter 3.27.4 consumes the pure-Dart parser', (tester) async {
    final output = MhchemParser.convert('H2O', mode: MhchemMode.ce);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text(output),
      ),
    );

    expect(find.text(output), findsOneWidget);
    expect(output, contains(r'\mathrm{H}'));
  });
}
