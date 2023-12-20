// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:getx_route_annotations/getx_route_annotations.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

class GetXRouteScanAnnotationBuilder extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;
    var libraryElement = await buildStep.resolver
        .libraryFor(buildStep.inputId, allowSyntaxErrors: true);
    var libraryReader = LibraryReader(libraryElement);
    final routesMap = <String, String>{};

    for (var annotatedElement in libraryReader.annotatedWith(
      TypeChecker.fromRuntime(GetXRoutePage),
      throwOnUnresolved: true,
    )) {
      final routeName =
          annotatedElement.annotation.read("routeName").stringValue;
      final className = annotatedElement.element.name;
      var import =
          "import 'package:${buildStep.inputId.package}/${annotatedElement.element.source?.fullName.split('/lib/')[1]}';";
      routesMap[className!] =
          'GetPage(name: \'$routeName\', page: () => $className()),';

      var item =
          RouteItem(routeName: routeName, import: import, className: className);
      buildStep.writeAsString(
          buildStep.inputId.changeExtension(".table.json"), item.toJson());
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        ".dart": [".table.json"]
      };
}

class GetXRouteTableGenerateBuilder extends Builder {
  final routesMap = <String, String>{};
  var imports = [];
  bool hasGenerate = false;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    print("!!!!GetXRouteTableGenerateBuilder");
    if (hasGenerate) {
      return;
    }
    hasGenerate = true;

    await for (final asset in buildStep.findAssets(Glob("**.table.json"))) {
      var item = RouteItem.fromJson(await buildStep.readAsString(asset));
      imports.add(item.import);
      routesMap[item.routeName] = item.className;
      print(item.toJson());
    }

    if (routesMap.isEmpty) {
      return;
    }
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("// ignore_for_file: constant_identifier_names");
    stringBuffer.writeln('import \'package:get/get.dart\';');
    for (var element in imports) {
      stringBuffer.writeln(element);
    }
    stringBuffer.writeln("");
    stringBuffer.writeln('class RouteTable {');
    routesMap.forEach((route, className) {
      var routeVariableName = route;
      if (route == "/") {
        routeVariableName = "mainPage";
      } else {
        routeVariableName = route.replaceAll('/', '_');
      }

      if (routeVariableName.startsWith("_")) {
        routeVariableName = routeVariableName.substring(1);
      }

      stringBuffer
          .writeln('  static const String $routeVariableName = \'$route\';');
    });
    stringBuffer.writeln('');

    stringBuffer.writeln('  static final List<GetPage> pages = [');
    routesMap.forEach((routeName, className) {
      stringBuffer.writeln(
          '    GetPage(name: \'$routeName\', page: () => $className()),');
    });
    stringBuffer.writeln('  ];');
    stringBuffer.writeln('}');
    stringBuffer.writeln('');

    var file = File("lib/generated/route_table.dart");
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(stringBuffer.toString());
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        ".dart": ["*.dart"]
      };
}

class RouteItem {
  String routeName;
  String import;
  String className;
  RouteItem({
    this.routeName = '',
    this.import = '',
    this.className = '',
  });

  RouteItem copyWith({
    String? routeName,
    String? import,
    String? className,
  }) {
    return RouteItem(
      routeName: routeName ?? this.routeName,
      import: import ?? this.import,
      className: className ?? this.className,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'routeName': routeName,
      'import': import,
      'className': className,
    };
  }

  factory RouteItem.fromMap(Map<String, dynamic> map) {
    return RouteItem(
      routeName: (map['routeName'] ?? '') as String,
      import: (map['import'] ?? '') as String,
      className: (map['className'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory RouteItem.fromJson(String source) =>
      RouteItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'RouteItem(routeName: $routeName, import: $import, className: $className)';

  @override
  bool operator ==(covariant RouteItem other) {
    if (identical(this, other)) return true;

    return other.routeName == routeName &&
        other.import == import &&
        other.className == className;
  }

  @override
  int get hashCode => routeName.hashCode ^ import.hashCode ^ className.hashCode;
}
