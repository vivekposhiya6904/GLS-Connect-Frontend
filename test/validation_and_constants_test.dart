import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_management/utils/city_constants.dart';
import 'package:alumni_management/utils/url_helper.dart';

void main() {
  group('CityConstants Tests', () {
    test('Canonical cities list is sorted alphabetically A to Z', () {
      final cities = CityConstants.canonicalCities;
      final sorted = List<String>.from(cities)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(cities, equals(sorted));
    });

    test('Canonical cities list has no duplicates', () {
      final cities = CityConstants.canonicalCities;
      final set = cities.map((c) => c.toLowerCase()).toSet();
      expect(set.length, equals(cities.length));
    });

    test('Filter cities starts with "All" and includes canonical cities', () {
      final filters = CityConstants.filterCities;
      expect(filters.first, equals("All"));
      expect(filters.length, equals(CityConstants.canonicalCities.length + 1));
      expect(filters.contains("Ahmedabad"), isTrue);
      expect(filters.contains("Mumbai"), isTrue);
      expect(filters.contains("Pune"), isTrue);
    });

    test('Preserves legacy names and maps canonical aliases', () {
      expect(CityConstants.matchCanonicalCity("Bangalore"), contains("Bengaluru"));
      expect(CityConstants.matchCanonicalCity("Delhi"), contains("Delhi"));
      expect(CityConstants.matchCanonicalCity("Ahmedabad"), equals("Ahmedabad"));
      expect(CityConstants.matchCanonicalCity("UnknownCity"), equals("UnknownCity"));
      expect(CityConstants.matchCanonicalCity(null), isNull);
    });

    test('Dropdown options dynamically includes edit record city', () {
      final options = CityConstants.getDropdownOptions(currentCity: "CustomTown");
      expect(options.contains("CustomTown"), isTrue);
      expect(options.contains("Ahmedabad"), isTrue);
    });
  });

  group('UrlHelper Tests', () {
    test('Normalizes URL lacking scheme to https://', () {
      final uri = UrlHelper.parseAndNormalizeUrl("example.com/careers");
      expect(uri, isNotNull);
      expect(uri!.scheme, equals("https"));
      expect(uri.host, equals("example.com"));
      expect(uri.path, equals("/careers"));
    });

    test('Retains existing http or https scheme', () {
      final uriHttps = UrlHelper.parseAndNormalizeUrl("https://company.org");
      expect(uriHttps, isNotNull);
      expect(uriHttps!.scheme, equals("https"));

      final uriHttp = UrlHelper.parseAndNormalizeUrl("http://company.org");
      expect(uriHttp, isNotNull);
      expect(uriHttp!.scheme, equals("http"));
    });

    test('Rejects empty or blank URLs', () {
      expect(UrlHelper.parseAndNormalizeUrl(""), isNull);
      expect(UrlHelper.parseAndNormalizeUrl("   "), isNull);
      expect(UrlHelper.parseAndNormalizeUrl(null), isNull);
    });
  });
}
