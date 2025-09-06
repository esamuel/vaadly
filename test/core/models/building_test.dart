import 'package:flutter_test/flutter_test.dart';
import 'package:vaadly/core/models/building.dart';

void main() {
  group('Building model', () {
    test('toMap/fromMap roundtrip preserves key fields', () {
      final b = Building(
        id: 'b1',
        buildingCode: 'B-ARL12',
        name: 'אירלוזר 12',
        address: 'אירלוזר 12',
        city: 'תל אביב',
        postalCode: '99999',
        country: 'IL',
        totalFloors: 9,
        totalUnits: 38,
        parkingSpaces: 10,
        storageUnits: 5,
        buildingArea: 1200.5,
        yearBuilt: 1999,
        buildingType: 'residential',
        amenities: const ['gym', 'garden'],
        createdAt: DateTime.utc(2024, 1, 2),
        updatedAt: DateTime.utc(2024, 3, 4),
        isActive: true,
      );

      final map = b.toMap();
      final b2 = Building.fromMap(map, b.id);

      expect(b2.id, b.id);
      expect(b2.buildingCode, b.buildingCode);
      expect(b2.name, b.name);
      expect(b2.city, b.city);
      expect(b2.totalUnits, b.totalUnits);
      expect(b2.amenities, b.amenities);
      expect(b2.isActive, b.isActive);
    });
  });
}
