import 'dart:math' as math;

import 'package:flutter_map/src/geo/latlng.dart';
import 'package:vector_math/vector_math_64.dart';

/// Data structure representing rectangular bounding box constrained by its
/// northwest and southeast corners
class LatLngBounds {
  late LatLng _sw;
  late LatLng _ne;

  LatLngBounds(
    LatLng corner1,
    LatLng corner2,
  ) : this.fromPoints([corner1, corner2]);

  LatLngBounds.fromPoints(List<LatLng> points)
      : assert(
          points.isNotEmpty,
          'LatLngBounds cannot be created with an empty List of LatLng',
        ) {
    double minX = 180;
    double maxX = -180;
    double minY = 90;
    double maxY = -90;

    for (final point in points) {
      minX = math.min<double>(minX, point.lon);
      minY = math.min<double>(minY, point.lat);
      maxX = math.max<double>(maxX, point.lon);
      maxY = math.max<double>(maxY, point.lat);
    }

    _sw = (lat: minY, lon: minX);
    _ne = (lat: maxY, lon: maxX);
  }

  /// Expands bounding box by [latLng] coordinate point. This method mutates
  /// the bounds object on which it is called.
  void extend(LatLng latLng) {
    _extend(latLng, latLng);
  }

  /// Expands bounding box by other [bounds] object. If provided [bounds] object
  /// is smaller than current one, it is not shrunk. This method mutates
  /// the bounds object on which it is called.
  void extendBounds(LatLngBounds bounds) {
    _extend(bounds._sw, bounds._ne);
  }

  void _extend(LatLng sw2, LatLng ne2) {
    _sw = (
      lat: math.min(sw2.lat, _sw.lat),
      lon: math.min(sw2.lon, _sw.lon),
    );
    _ne = (
      lat: math.max(ne2.lat, _ne.lat),
      lon: math.max(ne2.lon, _ne.lon),
    );
  }

  /// Obtain west edge of the bounds
  double get west => southWest.lon;

  /// Obtain south edge of the bounds
  double get south => southWest.lat;

  /// Obtain east edge of the bounds
  double get east => northEast.lon;

  /// Obtain north edge of the bounds
  double get north => northEast.lat;

  /// Obtain coordinates of southwest corner of the bounds
  LatLng get southWest => _sw;

  /// Obtain coordinates of northeast corner of the bounds
  LatLng get northEast => _ne;

  /// Obtain coordinates of northwest corner of the bounds
  LatLng get northWest => (lat: north, lon: west);

  /// Obtain coordinates of southeast corner of the bounds
  LatLng get southEast => (lat: south, lon: east);

  /// Obtain coordinates of the bounds center
  LatLng get center {
    /* https://stackoverflow.com/a/4656937
       http://www.movable-type.co.uk/scripts/latlong.html

       coord 1: southWest
       coord 2: northEast

       phi: lat
       lambda: lng
    */

    final phi1 = southWest.lat * degrees2Radians;
    final lambda1 = southWest.lon * degrees2Radians;
    final phi2 = northEast.lat * degrees2Radians;

    final dLambda = degrees2Radians *
        (northEast.lon - southWest.lon); // delta lambda = lambda2-lambda1

    final bx = math.cos(phi2) * math.cos(dLambda);
    final by = math.cos(phi2) * math.sin(dLambda);
    final phi3 = math.atan2(math.sin(phi1) + math.sin(phi2),
        math.sqrt((math.cos(phi1) + bx) * (math.cos(phi1) + bx) + by * by));
    final lambda3 = lambda1 + math.atan2(by, math.cos(phi1) + bx);

    // phi3 and lambda3 are actually in radians and LatLng wants degrees
    return (lat: radians2Degrees * phi3, lon: radians2Degrees * lambda3);
  }

  /// Checks whether [point] is inside bounds
  bool contains(LatLng point) {
    final sw2 = point;
    final ne2 = point;
    return containsBounds(LatLngBounds(sw2, ne2));
  }

  /// Checks whether [bounds] is contained inside bounds
  bool containsBounds(LatLngBounds bounds) {
    final sw2 = bounds._sw;
    final ne2 = bounds._ne;
    return (sw2.lat >= _sw.lat) &&
        (ne2.lat <= _ne.lat) &&
        (sw2.lon >= _sw.lon) &&
        (ne2.lon <= _ne.lon);
  }

  /// Checks whether at least one edge of [bounds] is overlapping with some
  /// other edge of bounds
  bool isOverlapping(LatLngBounds bounds) {
    /* check if bounding box rectangle is outside the other, if it is then it's
       considered not overlapping
    */
    if (_sw.lat > bounds._ne.lat ||
        _ne.lat < bounds._sw.lat ||
        _ne.lon < bounds._sw.lon ||
        _sw.lon > bounds._ne.lon) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(_sw, _ne);

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds && other._sw == _sw && other._ne == _ne;
}
