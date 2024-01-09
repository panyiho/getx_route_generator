// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:getx_route_annotations/getx_route_annotations.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as p;

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
      final typeList =
          annotatedElement.annotation.read("dependencies").listValue;
      Set<String> imports = {};
      Set<String> dependencies = {};
      for (var element in typeList) {
        dependencies.add(element.toTypeValue()?.element?.displayName ?? "");
        var importStr =
            element.toTypeValue()?.element?.library?.source.uri.toString();
        if (importStr != null && importStr.isNotEmpty) {
          imports.add("import '$importStr';");
        }
      }
      final className = annotatedElement.element.name;
      imports.add(
          "import 'package:${buildStep.inputId.package}/${annotatedElement.element.source?.fullName.split('/lib/')[1]}';");
      routesMap[className!] =
          'GetPage(name: \'$routeName\', page: () => $className()),';

      var item = RouteItem(
          routeName: routeName,
          import: imports,
          className: className,
          dependencies: dependencies);
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
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final routesMap = <String, RouteItem>{};
    var imports = <String>{};
    await for (final asset in buildStep.findAssets(Glob("**.table.json"))) {
      var item = RouteItem.fromJson(await buildStep.readAsString(asset));
      imports.addAll(item.import);
      routesMap[item.routeName] = item;
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
    routesMap.forEach((route, item) {
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
    routesMap.forEach((routeName, item) {
      stringBuffer.write(
          '    GetPage(name: \'$routeName\', page: () => ${item.className}(),');
      if (item.dependencies.isNotEmpty) {
        stringBuffer.writeln("binding: BindingsBuilder(() {");
        for (var dependence in item.dependencies) {
          stringBuffer
              .writeln("    Get.lazyPut<$dependence>(() => $dependence());");
        }
        stringBuffer.writeln(" }),");
      }

      stringBuffer.writeln('),');
    });
    stringBuffer.writeln('  ];');
    stringBuffer.writeln('}');
    stringBuffer.writeln('');

    var formatter = DartFormatter();
    await buildStep.writeAsString(
        AssetId(
          buildStep.inputId.package,
          p.join('lib', "generated", 'route_table.dart'),
        ),
        formatter.format(stringBuffer.toString()));
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['/generated/route_table.dart'],
    };
  }
}

class RouteItem {
  String routeName;
  Set<String> import;
  String className;
  Set<String> dependencies;
  RouteItem({
    this.routeName = '',
    this.import = const {},
    this.className = '',
    this.dependencies = const {},
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'routeName': routeName,
      'import': import.toList(),
      'className': className,
      'dependencies': dependencies.toList(),
    };
  }

  factory RouteItem.fromMap(Map<String, dynamic> map) {
    return RouteItem(
      routeName: (map['routeName'] ?? '') as String,
      import:
          (map['import'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
              const {},
      className: (map['className'] ?? '') as String,
      dependencies: (map['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
    );
  }

  String toJson() => json.encode(toMap());

  factory RouteItem.fromJson(String source) =>
      RouteItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
