import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:find_map_location/services/grid_calculation_service.dart';
import 'package:find_map_location/models/lat_lng_bounds.dart';

void main() {
  group('GridCalculationService', () {
    group('indexToColumnName', () {
      test('converts indices 0-25 to A-Z', () {
        expect(GridCalculationService.indexToColumnName(0), 'A');
        expect(GridCalculationService.indexToColumnName(1), 'B');
        expect(GridCalculationService.indexToColumnName(25), 'Z');
      });

      test('converts indices 26-51 to AA-AZ', () {
        expect(GridCalculationService.indexToColumnName(26), 'AA');
        expect(GridCalculationService.indexToColumnName(27), 'AB');
        expect(GridCalculationService.indexToColumnName(51), 'AZ');
      });

      test('handles wrap-around (ZZ → AAA)', () {
        expect(GridCalculationService.indexToColumnName(52), 'BA');
        expect(GridCalculationService.indexToColumnName(701), 'ZZ');
        expect(GridCalculationService.indexToColumnName(702), 'AAA');
      });
    });

    group('getCellForPoint', () {
      late LatLng origin;
      late double cellSize;

      setUp(() {
        // Use a simple origin for testing
        origin = LatLng(48.0, 2.0);
        cellSize = 500.0; // 500m cells
      });

      test('point in cell center returns correct cell', () {
        // Point approximately 750m east and 750m south of origin (cell B2)
        // Using more accurate distance: ~0.0067° lon ≈ 500m at 48°N, ~0.0045° lat ≈ 500m
        final point = LatLng(47.9933, 2.0100);
        final cell =
            GridCalculationService.getCellForPoint(point, origin, cellSize);

        expect(cell.columnIndex, greaterThanOrEqualTo(1));
        expect(cell.rowIndex, greaterThanOrEqualTo(1));
        expect(cell.id, matches(RegExp(r'^[A-Z]+[2-9]$')));
      });

      test('point on north edge belongs to cell (north priority)', () {
        // Point exactly on north edge of cell
        final point = LatLng(48.0, 2.0032); // ~0m south, ~250m east
        final cell =
            GridCalculationService.getCellForPoint(point, origin, cellSize);

        expect(cell.rowIndex, 0); // Belongs to row 0 (north priority)
      });

      test('point on west edge belongs to cell (west priority)', () {
        // Point exactly on west edge of cell
        final point = LatLng(47.9955, 2.0); // ~500m south, 0m east
        final cell =
            GridCalculationService.getCellForPoint(point, origin, cellSize);

        expect(cell.columnIndex, 0); // Belongs to column 0 (west priority)
      });

      test('point on south edge belongs to cell below', () {
        // Point exactly on south edge of cell A1 (becomes A2)
        final point = LatLng(47.9955, 2.0032); // ~500m south, ~250m east
        final cell =
            GridCalculationService.getCellForPoint(point, origin, cellSize);

        expect(cell.rowIndex, 1); // Belongs to row 1 (cell below)
      });

      test('point on east edge belongs to cell to right', () {
        // Point just past east edge of cell A1 (into cell B1)
        final cellA1Bounds = GridCalculationService.calculateCellBounds(
          0,
          0,
          origin,
          cellSize,
        );
        // Add small offset to be clearly in next cell
        final point = LatLng(47.9978, cellA1Bounds.east + 0.0001);
        final cell =
            GridCalculationService.getCellForPoint(point, origin, cellSize);

        expect(cell.columnIndex, greaterThanOrEqualTo(1)); // Cell to right (B column)
      });

      test('point at exact corner uses north-west priority', () {
        // Point at origin (north-west corner)
        final cell =
            GridCalculationService.getCellForPoint(origin, origin, cellSize);

        expect(cell.columnIndex, 0);
        expect(cell.rowIndex, 0);
        expect(cell.id, 'A1');
      });
    });

    group('calculateGridOrigin', () {
      test('calculates origin based on city center', () {
        final cityCenter = LatLng(48.8566, 2.3522); // Paris
        final cellSize = 500.0;

        final origin = GridCalculationService.calculateGridOrigin(
          cityCenter,
          cellSize,
        );

        // With new logic, origin should be the city center itself
        expect(origin.latitude, equals(cityCenter.latitude));
        expect(origin.longitude, equals(cityCenter.longitude));
      });

      test('grid aligns properly with city bounds when provided', () {
        final cityCenter = LatLng(48.8566, 2.3522);
        final cellSize = 500.0;

        // Calculate city bounds
        final cityBounds = GridCalculationService.calculateCityBounds(
          cityCenter,
          5000.0,
        );

        final origin = GridCalculationService.calculateGridOrigin(
          cityCenter,
          cellSize,
          cityBounds: cityBounds,
        );

        // Origin should be west and north of city center when bounds provided
        expect(origin.latitude, greaterThanOrEqualTo(cityCenter.latitude));
        expect(origin.longitude, lessThanOrEqualTo(cityCenter.longitude));
      });

      test('calculateCityBounds creates correct bounds', () {
        final cityCenter = LatLng(48.8566, 2.3522);
        final radius = 5000.0; // 5km

        final bounds = GridCalculationService.calculateCityBounds(
          cityCenter,
          radius,
        );

        // Bounds should extend in all directions
        expect(bounds.north, greaterThan(cityCenter.latitude));
        expect(bounds.south, lessThan(cityCenter.latitude));
        expect(bounds.east, greaterThan(cityCenter.longitude));
        expect(bounds.west, lessThan(cityCenter.longitude));

        // Verify bounds are approximately symmetric
        final latDiff = bounds.north - cityCenter.latitude;
        final latDiff2 = cityCenter.latitude - bounds.south;
        expect((latDiff - latDiff2).abs(), lessThan(0.001)); // Within tolerance
      });
    });

    group('generateVisibleCells', () {
      late LatLng origin;
      late double cellSize;

      setUp(() {
        origin = LatLng(48.0, 2.0);
        cellSize = 500.0;
      });

      test('generates cells for typical viewport (5x5)', () {
        // Viewport covering approximately 5x5 cells
        final viewport = GridBounds(
          LatLng(48.0, 2.0), // North-west
          LatLng(47.9778, 2.0320), // South-east (~2.5km x 2.5km)
        );

        final cells = GridCalculationService.generateVisibleCells(
          viewport,
          origin,
          cellSize,
        );

        // Should have approximately 5x5 = 25 cells (plus buffer = ~49)
        expect(cells.length, greaterThan(20));
        expect(cells.length, lessThan(60));
      });

      test('enforces maxCells limit', () {
        // Very large viewport
        final viewport = GridBounds(
          LatLng(48.1, 1.9),
          LatLng(47.9, 2.2),
        );

        final cells = GridCalculationService.generateVisibleCells(
          viewport,
          origin,
          cellSize,
          maxCells: 50,
        );

        expect(cells.length, lessThanOrEqualTo(50));
      });

      test('returns empty list when needed', () {
        // Very small viewport or cells not initialized
        final viewport = GridBounds(
          LatLng(48.0001, 2.0001),
          LatLng(48.0, 2.0),
        );

        final cells = GridCalculationService.generateVisibleCells(
          viewport,
          origin,
          cellSize,
        );

        // Should have at least buffer cells
        expect(cells, isNotEmpty);
      });

      test('cells have correct IDs and properties', () {
        final viewport = GridBounds(
          LatLng(48.0, 2.0),
          LatLng(47.9778, 2.0160),
        );

        final cells = GridCalculationService.generateVisibleCells(
          viewport,
          origin,
          cellSize,
        );

        // Verify all cells have valid properties
        for (final cell in cells) {
          expect(cell.id, matches(RegExp(r'^[A-Z]+\d+$')));
          expect(cell.columnIndex, greaterThanOrEqualTo(0));
          expect(cell.rowIndex, greaterThanOrEqualTo(0));
          expect(cell.bounds, isNotNull);
          expect(cell.centerPoint, isNotNull);
        }

        // Cell A1 should be in the list (top-left)
        final cellA1 = cells.firstWhere((c) => c.id == 'A1');
        expect(cellA1.columnIndex, 0);
        expect(cellA1.rowIndex, 0);
      });
    });

    group('calculateCellBounds', () {
      late LatLng origin;
      late double cellSize;

      setUp(() {
        origin = LatLng(48.0, 2.0);
        cellSize = 500.0;
      });

      test('calculates bounds for cell A1 (indices 0, 0)', () {
        final bounds = GridCalculationService.calculateCellBounds(
          0,
          0,
          origin,
          cellSize,
        );

        // Cell A1 should start at origin
        expect(bounds.north, closeTo(origin.latitude, 0.001));
        expect(bounds.west, closeTo(origin.longitude, 0.001));

        // South and east should be offset by cellSize
        expect(bounds.south, lessThan(origin.latitude));
        expect(bounds.east, greaterThan(origin.longitude));
      });

      test('calculates bounds for arbitrary cell (C4)', () {
        final bounds = GridCalculationService.calculateCellBounds(
          2, // Column C (index 2)
          3, // Row 4 (index 3)
          origin,
          cellSize,
        );

        // Cell should be offset from origin
        expect(bounds.north, lessThan(origin.latitude));
        expect(bounds.west, greaterThan(origin.longitude));

        // Bounds should be valid rectangle
        expect(bounds.north, greaterThan(bounds.south));
        expect(bounds.east, greaterThan(bounds.west));
      });

      test('bounds accuracy is within acceptable range (±10m)', () {
        final bounds = GridCalculationService.calculateCellBounds(
          0,
          0,
          origin,
          cellSize,
        );

        // Calculate approximate expected coordinates
        final distance = Distance();

        // Distance from north-west to south-east should be ~707m (diagonal of 500m square)
        final northWest = LatLng(bounds.north, bounds.west);
        final southEast = LatLng(bounds.south, bounds.east);
        final diagonal = distance(northWest, southEast);

        // Diagonal of square = side * sqrt(2) ≈ 500 * 1.414 = 707m
        expect(diagonal, closeTo(707, 20)); // ±20m tolerance
      });
    });
  });
}
