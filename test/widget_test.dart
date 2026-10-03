import 'package:fdp_app/words.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes rupee amounts in Indian words', () {
    expect(amountInWords(5000), 'Rupees Five Thousand Only');
    expect(amountInWords(121), 'Rupees One Hundred Twenty One Only');
    expect(amountInWords(100000), 'Rupees One Lakh Only');
    expect(amountInWords(1500.5), 'Rupees One Thousand Five Hundred and Fifty Paise Only');
  });
}
