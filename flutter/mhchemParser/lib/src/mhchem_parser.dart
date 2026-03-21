import 'mhchem_parser_core.dart';
import 'mhchem_texify.dart';

class MhchemParser {
  static String toTex(String input, String type) {
    return MhchemTexify.go(MhchemParserCore.go(input, type), type != 'tex');
  }
}
