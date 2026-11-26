import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/screens/services/vin_lookup_screen.dart';

void main() {
  group('cleanVin', () {
    test('uppercases a lowercase pasted VIN', () {
      expect(cleanVin('1hgcm82633a004352'), '1HGCM82633A004352');
    });

    test('strips the forbidden letters I, O and Q', () {
      // I->gone, O->gone, Q->gone; remaining chars keep their order.
      expect(cleanVin('IOQ123'), '123');
      expect(cleanVin('1I2O3Q4'), '1234');
    });

    test('strips spaces and punctuation from a pasted value', () {
      expect(cleanVin('  1HG CM8-26 33A004352 '), '1HGCM82633A004352');
    });

    test('caps length at 17 characters', () {
      final result = cleanVin('1HGCM82633A00435200000');
      expect(result.length, 17);
      expect(result, '1HGCM82633A004352');
    });

    test('leaves a clean valid VIN unchanged', () {
      expect(cleanVin('5YJSA1E26HF000337'), '5YJSA1E26HF000337');
    });

    test('empty stays empty', () {
      expect(cleanVin(''), '');
    });
  });
}
