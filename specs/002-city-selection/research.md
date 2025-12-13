# Research: City Selection for Duplicate Postal Codes

**Feature**: 002-city-selection
**Date**: 2025-12-13
**Purpose**: Research API capabilities for multiple cities per postal code, Flutter list UI patterns, and disambiguation strategies

## Research Tasks Completed

### 1. API Adresse Multiple Cities Support

**Decision**: Use `limit=50` parameter with API Adresse to retrieve all cities for a postal code

**Rationale**:
- API Adresse (api-adresse.data.gouv.fr) already used in feature 001 supports retrieving multiple results
- Current implementation uses `limit=1` which only returns first city
- Changing `limit=1` to `limit=50` will return all cities sharing the postal code
- French postal codes typically have 1-10 cities; `limit=50` provides safe buffer
- Response includes `city`, `context` (department), and `coordinates` for each result
- No additional API calls needed; single request returns all cities

**API Endpoint Update**:
```
GET https://api-adresse.data.gouv.fr/search/?q={postalCode}&type=municipality&limit=50
```

**Response Format** (multiple cities):
```json
{
  "features": [
    {
      "geometry": {
        "coordinates": [6.0236, 46.2436]
      },
      "properties": {
        "label": "Saint-Genis-Pouilly, Ain",
        "postcode": "01630",
        "city": "Saint-Genis-Pouilly",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    },
    {
      "geometry": {
        "coordinates": [6.0123, 46.1987]
      },
      "properties": {
        "label": "Péron, Ain",
        "postcode": "01630",
        "city": "Péron",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    },
    {
      "geometry": {
        "coordinates": [6.0445, 46.2589]
      },
      "properties": {
        "label": "Sergy, Ain",
        "postcode": "01630",
        "city": "Sergy",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    }
  ]
}
```

**Implementation Notes**:
- Modify `GeocodingService` to return `List<City>` instead of single `CityLocation`
- Parse all features from JSON response, not just first element
- Extract department from `context` field for disambiguation
- No breaking changes to API contract; just parameter adjustment

**Testing Requirements**:
- Test with known multi-city postal codes: "01630" (3 cities), "35530" (2 cities)
- Verify limit=50 handles edge cases (postal codes with 10+ cities)
- Mock HTTP responses with 1, 2, 5, and 10 cities for unit tests

---

### 2. Flutter List Selection UI Patterns

**Decision**: Use `ListView.builder` with `ListTile` widgets for city selection

**Rationale**:
- **ListView.builder** is Flutter's standard widget for scrollable lists with lazy loading
- Efficient for lists of any size (only builds visible items)
- **ListTile** provides Material Design-compliant list item layout
- Built-in tap handling via `onTap` callback
- Supports leading icons, subtitles for disambiguation information
- Automatically respects theme configuration and accessibility

**UI Pattern**:
```dart
ListView.builder(
  itemCount: cities.length,
  itemBuilder: (context, index) {
    final city = cities[index];
    return ListTile(
      title: Text(city.name),
      subtitle: Text(city.department), // For disambiguation
      onTap: () {
        // Navigate to map with selected city
      },
    );
  },
)
```

**Alternatives Considered**:
1. **GridView**: Better for image-based selections; overkill for text lists. Rejected.
2. **Custom ScrollView**: More complex; ListView.builder sufficient. Rejected.
3. **DropdownButton**: Limited to ~20 items; poor UX for scrolling. Rejected.

**Accessibility Considerations**:
- ListTile automatically provides semantic labels for screen readers
- Each item will announce: "[City Name], [Department], button"
- Sufficient touch target size (48dp minimum per Material Design)

**Implementation Notes**:
- Wrap ListView in Scaffold with AppBar showing "Select City" title
- Add Divider between items for visual separation
- Consider alphabetical sorting for better scannability
- Handle empty list edge case (show error message)

---

### 3. City Disambiguation Strategy

**Decision**: Display department name in subtitle when cities share same postal code

**Rationale**:
- API Adresse provides `context` field containing department information
- Format: "01, Ain, Auvergne-Rhône-Alpes"
- Extract department name (second element: "Ain") for concise display
- Sufficient for most disambiguation cases (cities with same name in different departments)
- Familiar convention in France (city name + department)

**Disambiguation Format**:
- Primary text: City name (e.g., "Saint-Genis-Pouilly")
- Secondary text: Department (e.g., "Ain")
- Full format: "Saint-Genis-Pouilly\nAin"

**Edge Cases**:
1. **Same city name, same department**: Extremely rare. Use full `label` from API if needed
2. **Missing context field**: Fall back to city name only
3. **Very long city names**: ListTile handles text wrapping automatically

**Implementation Notes**:
- Parse `context` field: `"01, Ain, Auvergne-Rhône-Alpes".split(',')[1].trim()`
- Store department in City model for easy access
- Consider caching parsed department to avoid repeated string operations

---

### 4. Navigation and State Management

**Decision**: Use Navigator.push for city selection screen, return selected City via Navigator.pop

**Rationale**:
- Standard Flutter navigation pattern for selection flows
- PostalCodeScreen pushes CitySelectionScreen onto navigation stack
- User selects city → CitySelectionScreen pops with selected City
- PostalCodeScreen receives City and updates map
- No additional state management library needed (consistent with feature 001)

**Navigation Flow**:
```dart
// In PostalCodeScreen, when multiple cities returned:
final selectedCity = await Navigator.push<City>(
  context,
  MaterialPageRoute(
    builder: (context) => CitySelectionScreen(cities: cities),
  ),
);

if (selectedCity != null) {
  _updateMap(selectedCity);
}

// In CitySelectionScreen, on city tap:
Navigator.pop(context, selectedCity);
```

**Back Button Handling**:
- Android back button: Automatically calls Navigator.pop(context, null)
- iOS back swipe: Same behavior
- AppBar back button: Same behavior
- Check for null return value in PostalCodeScreen

**Alternatives Considered**:
1. **Modal Bottom Sheet**: Good for short lists (<5 items), but limited vertical space. Rejected.
2. **Dialog**: Poor UX for scrollable content. Rejected.
3. **State Management Library (Provider/Riverpod)**: Overkill for simple navigation flow. Rejected.

**Implementation Notes**:
- Pass `List<City>` as constructor parameter to CitySelectionScreen
- Return type: `Future<City?>` from Navigator.push
- Handle null return (user pressed back without selecting)

---

### 5. Request Cancellation for Rapid Input Changes

**Decision**: Reuse existing request cancellation pattern from feature 001

**Rationale**:
- Feature 001 already implements latest-wins pattern for rapid postal code submissions
- Same pattern applies: cancel pending geocoding request when new postal code entered
- No changes needed to cancellation logic; works for both single and multi-city results

**Implementation Notes**:
- Existing `GeocodingService` uses `http.Client` with timeout
- Track pending Future in PostalCodeScreen state
- Cancel previous request before starting new lookup
- City selection screen doesn't need cancellation (no async operations)

---

## Summary of Technical Decisions

| Area | Decision | Dependencies |
|------|----------|--------------|
| **API Changes** | Change limit=1 to limit=50 in API Adresse endpoint | None (existing API) |
| **Service Layer** | Return `List<City>` from GeocodingService | New City model |
| **UI Widget** | ListView.builder + ListTile for selection | Flutter Material |
| **Disambiguation** | Department name in subtitle | Parse API context field |
| **Navigation** | Navigator.push/pop pattern | None (built-in) |
| **State Management** | StatefulWidget (consistent with 001) | None |

## Open Questions Resolved

1. **Q: Does API Adresse support multiple cities per postal code?**
   - A: YES. Use `limit=50` parameter to retrieve all cities

2. **Q: How to disambiguate cities with identical names?**
   - A: Use department name from `context` field in API response

3. **Q: What UI pattern for city selection?**
   - A: ListView.builder with ListTile (Material Design standard)

4. **Q: How to handle navigation between screens?**
   - A: Navigator.push/pop with City return value

5. **Q: Need new dependencies?**
   - A: NO. All features achievable with existing dependencies

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| API returns >50 cities for single postal code | Unlikely in French postal system; monitor in production; increase limit if needed |
| Missing `context` field in API response | Add null safety checks; fall back to city name only |
| Very long city names cause UI overflow | ListTile handles text wrapping automatically; test with longest known names |
| User confusion with similar city names | Department name provides clear disambiguation; add integration tests |

## Next Steps (Phase 1)

1. Define City model with name, coordinates, department fields
2. Update GeocodingService contract to return List<City>
3. Design CitySelectionScreen widget
4. Document API contract changes in contracts/geocoding-api.md
