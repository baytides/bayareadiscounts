import 'package:flutter_test/flutter_test.dart';
import 'package:baynavigator/models/program.dart';

void main() {
  group('Program', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'test-program',
        'name': 'Test Program',
        'category': 'food',
        'description': 'A test program',
        'fullDescription': 'A full description',
        'groups': ['seniors', 'low-income'],
        'areas': ['San Francisco', 'Bay Area'],
        'website': 'https://example.com',
        'lastUpdated': '2024-01-01',
      };

      final program = Program.fromJson(json);

      expect(program.id, 'test-program');
      expect(program.name, 'Test Program');
      expect(program.category, 'food');
      expect(program.description, 'A test program');
      expect(program.fullDescription, 'A full description');
      expect(program.groups, ['seniors', 'low-income']);
      expect(program.areas, ['San Francisco', 'Bay Area']);
      expect(program.website, 'https://example.com');
      expect(program.lastUpdated, '2024-01-01');
    });

    test('fromJson handles legacy eligibility field', () {
      final json = {
        'id': 'legacy-program',
        'name': 'Legacy Program',
        'category': 'utilities',
        'description': 'Uses old eligibility field',
        'eligibility': ['veterans', 'disabled'],
        'areas': ['Statewide'],
        'website': 'https://example.com',
        'lastUpdated': '2024-01-01',
      };

      final program = Program.fromJson(json);

      expect(program.groups, ['veterans', 'disabled']);
      expect(program.eligibility, ['veterans', 'disabled']);
    });

    test('toJson serializes correctly', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        category: 'health',
        description: 'Test desc',
        groups: ['seniors'],
        areas: ['Oakland'],
        website: 'https://test.com',
        lastUpdated: '2024-02-01',
      );

      final json = program.toJson();

      expect(json['id'], 'test');
      expect(json['name'], 'Test');
      expect(json['groups'], ['seniors']);
    });

    test('displayDescription prefers fullDescription', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        category: 'food',
        description: 'Short',
        fullDescription: 'Full description here',
        groups: [],
        areas: [],
        website: '',
        lastUpdated: '2024-01-01',
      );

      expect(program.displayDescription, 'Full description here');
    });

    test('displayDescription falls back to description', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        category: 'food',
        description: 'Short description',
        groups: [],
        areas: [],
        website: '',
        lastUpdated: '2024-01-01',
      );

      expect(program.displayDescription, 'Short description');
    });

    test('locationText returns city when available', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        category: 'food',
        description: 'Test',
        groups: [],
        areas: ['San Francisco'],
        city: 'Oakland',
        website: '',
        lastUpdated: '2024-01-01',
      );

      expect(program.locationText, 'Oakland');
    });

    test('locationText returns areas when no city', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        category: 'food',
        description: 'Test',
        groups: [],
        areas: ['San Francisco', 'Oakland'],
        website: '',
        lastUpdated: '2024-01-01',
      );

      expect(program.locationText, 'San Francisco, Oakland');
    });

    test('offerItems parses whatTheyOffer', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        category: 'food',
        description: 'Test',
        whatTheyOffer: '- Free meals\n- Grocery assistance\n- Delivery',
        groups: [],
        areas: [],
        website: '',
        lastUpdated: '2024-01-01',
      );

      expect(program.offerItems, ['Free meals', 'Grocery assistance', 'Delivery']);
    });

    test('howToSteps parses howToGetIt', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        category: 'food',
        description: 'Test',
        howToGetIt: '1. Visit website\n2. Fill form\n3. Submit',
        groups: [],
        areas: [],
        website: '',
        lastUpdated: '2024-01-01',
      );

      expect(program.howToSteps, ['Visit website', 'Fill form', 'Submit']);
    });
  });

  group('ProgramCategory', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'food',
        'name': 'Food & Groceries',
        'icon': 'restaurant',
        'programCount': 42,
      };

      final category = ProgramCategory.fromJson(json);

      expect(category.id, 'food');
      expect(category.name, 'Food & Groceries');
      expect(category.icon, 'restaurant');
      expect(category.programCount, 42);
    });
  });

  group('ProgramGroup', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'seniors',
        'name': 'Seniors',
        'description': 'Adults 65 and older',
        'icon': 'elderly',
        'programCount': 150,
      };

      final group = ProgramGroup.fromJson(json);

      expect(group.id, 'seniors');
      expect(group.name, 'Seniors');
      expect(group.description, 'Adults 65 and older');
      expect(group.programCount, 150);
    });
  });

  group('Area', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'san-francisco',
        'name': 'San Francisco',
        'type': 'county',
        'programCount': 200,
      };

      final area = Area.fromJson(json);

      expect(area.id, 'san-francisco');
      expect(area.name, 'San Francisco');
      expect(area.type, 'county');
      expect(area.programCount, 200);
    });
  });

  group('FilterState', () {
    test('default state has no filters', () {
      final state = FilterState();

      expect(state.categories, isEmpty);
      expect(state.groups, isEmpty);
      expect(state.areas, isEmpty);
      expect(state.searchQuery, '');
      expect(state.hasFilters, false);
    });

    test('copyWith creates new instance with changes', () {
      final state = FilterState(categories: ['food']);
      final newState = state.copyWith(groups: ['seniors']);

      expect(state.categories, ['food']);
      expect(state.groups, isEmpty);
      expect(newState.categories, ['food']);
      expect(newState.groups, ['seniors']);
    });

    test('hasFilters returns true when filters applied', () {
      expect(FilterState(categories: ['food']).hasFilters, true);
      expect(FilterState(groups: ['seniors']).hasFilters, true);
      expect(FilterState(areas: ['sf']).hasFilters, true);
      expect(FilterState(searchQuery: 'test').hasFilters, true);
    });

    test('filterCount counts correctly', () {
      final state = FilterState(
        categories: ['food', 'health'],
        groups: ['seniors'],
        areas: ['san-francisco', 'bay-area', 'statewide'],
        searchQuery: 'test',
      );

      // 2 categories + 1 group + 1 county + 1 "Other" (bay-area + statewide) + 1 search = 6
      expect(state.filterCount, 6);
    });
  });

  group('FilterPreset', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': '123',
        'name': 'My Preset',
        'filters': {
          'categories': ['food'],
          'groups': ['seniors'],
          'areas': ['sf'],
          'searchQuery': '',
        },
        'createdAt': '2024-01-01T00:00:00Z',
      };

      final preset = FilterPreset.fromJson(json);

      expect(preset.id, '123');
      expect(preset.name, 'My Preset');
      expect(preset.filters.categories, ['food']);
      expect(preset.filters.groups, ['seniors']);
    });

    test('fromJson handles legacy eligibility field', () {
      final json = {
        'id': '123',
        'name': 'Legacy Preset',
        'filters': {
          'categories': [],
          'eligibility': ['veterans'],
          'areas': [],
          'searchQuery': '',
        },
        'createdAt': '2024-01-01T00:00:00Z',
      };

      final preset = FilterPreset.fromJson(json);

      expect(preset.filters.groups, ['veterans']);
    });

    test('toJson serializes correctly', () {
      final preset = FilterPreset(
        id: '456',
        name: 'Test Preset',
        filters: FilterState(categories: ['health']),
        createdAt: '2024-02-01',
      );

      final json = preset.toJson();

      expect(json['id'], '456');
      expect(json['name'], 'Test Preset');
      expect(json['filters']['categories'], ['health']);
    });
  });

  group('APIMetadata', () {
    test('fromJson parses correctly', () {
      final json = {
        'version': '1.0.0',
        'generatedAt': '2024-01-01T12:00:00Z',
        'totalPrograms': 500,
      };

      final metadata = APIMetadata.fromJson(json);

      expect(metadata.version, '1.0.0');
      expect(metadata.generatedAt, '2024-01-01T12:00:00Z');
      expect(metadata.totalPrograms, 500);
    });
  });
}
