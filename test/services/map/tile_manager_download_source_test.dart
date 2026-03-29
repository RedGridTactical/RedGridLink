import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/constants/map_constants.dart';

void main() {
  test('tileUrlFor returns correct URL per source', () {
    expect(
      MapConstants.tileUrlFor('osm'),
      MapConstants.osmTileUrl,
    );
    expect(
      MapConstants.tileUrlFor('topo'),
      MapConstants.openTopoUrl,
    );
  });

  test('tileUrlFor defaults to OSM for unknown source', () {
    expect(
      MapConstants.tileUrlFor('unknown'),
      MapConstants.osmTileUrl,
    );
  });

  test('attributionFor returns correct attribution', () {
    expect(MapConstants.attributionFor('osm'), contains('OpenStreetMap'));
    expect(MapConstants.attributionFor('topo'), contains('OpenTopoMap'));
  });
}
