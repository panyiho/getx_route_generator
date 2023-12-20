import 'package:build/build.dart';

import 'getx_route_table_generator.dart';

Builder getXRouteTableGenerator(BuilderOptions options) {
  return GetXRouteTableGenerateBuilder();
}

Builder getXRouteScanAnnotation(BuilderOptions options) {
  return GetXRouteScanAnnotationBuilder();
}
