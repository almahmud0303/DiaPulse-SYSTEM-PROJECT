import 'package:dia_plus/services/mlkit_ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MlKitOcrService.parsePrescriptionText', () {
    test(
      'extracts medicine names, dosage, and timing from prescription text',
      () {
        final result = MlKitOcrService.parsePrescriptionText('''
Patient: Test User
1. Tab Metformin 500 mg 1+0+1 after meal x 30 days
2. Cap Omeprazole 20mg OD before breakfast for 14 days
3. Insulin Glargine 10 units at bedtime
''');

        expect(result.medicines, hasLength(3));

        expect(result.medicines[0].name, 'Metformin');
        expect(result.medicines[0].dosage, '500 mg');
        expect(result.medicines[0].timing, contains('1+0+1'));
        expect(
          result.medicines[0].timing.toLowerCase(),
          contains('after meal'),
        );

        expect(result.medicines[1].name, 'Omeprazole');
        expect(result.medicines[1].dosage, '20mg');
        expect(
          result.medicines[1].timing.toLowerCase(),
          contains('before breakfast'),
        );

        expect(result.medicines[2].name, 'Insulin Glargine');
        expect(result.medicines[2].dosage, '10 units');
        expect(result.medicines[2].timing.toLowerCase(), contains('bedtime'));
      },
    );

    test(
      'attaches timing-only continuation lines to the previous medicine',
      () {
        final result = MlKitOcrService.parsePrescriptionText('''
Tab Sitagliptin 50 mg
twice daily after meals
''');

        expect(result.medicines, hasLength(1));
        expect(result.medicines.single.name, 'Sitagliptin');
        expect(result.medicines.single.dosage, '50 mg');
        expect(
          result.medicines.single.timing.toLowerCase(),
          contains('twice daily'),
        );
        expect(
          result.medicines.single.timing.toLowerCase(),
          contains('after meals'),
        );
      },
    );
  });
}
