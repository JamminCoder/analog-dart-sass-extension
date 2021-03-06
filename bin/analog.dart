import 'package:sass/src/analog_css/analog_generator.dart';
import 'package:sass/src/analog_css/css_class_manager.dart';
import 'dart:io';


class StatementListener {
  static List<String> statements = [];

  Future<void> listen() async {
    var server = await HttpServer.bind(InternetAddress.anyIPv6, 8080);
    await server.forEach((HttpRequest request) {
      if (request.headers['statement'] != null) {
        String stmt = request.headers['statement']![0];
        if (!statements.contains(stmt)) statements.add(stmt);
      }

      request.response.write('OK');
      request.response.close();
    });

  }

  List<String> getStatements() { 
    return statements;
  }
}


void main(List<String> args) async {
  print('Checking markup for classes every 1 second...');

  File outFile = File('analog.scss');
  List<String> files = [];

  // Get files to watch
  for (String arg in args) {
    if (File(arg).existsSync()) files.add(arg);
  }

  String lastOutput = '';

  StatementListener().listen();

  while (true) {
    
    outFile.writeAsStringSync('');
    String currentOutput = '';
    
    CSSClassManager cssClassManager = CSSClassManager();
    
    List<String> classes = cssClassManager.getClassesFromFiles(files);

    var statements = StatementListener().getStatements();


    for (String statement in statements) {
      AnalogGenerator analogGenerator = AnalogGenerator(statement);
      List<String> cssClasses = analogGenerator.findMatchingCssClasses(classes);

      for (String cssClass in cssClasses) {
        if (cssClass == '') continue;

        String analogCssClass = analogGenerator.generateAnalogClass(cssClass);
        currentOutput += analogCssClass + '\n';
      }
      
      
    }
    
    if (lastOutput != currentOutput) {
      lastOutput = currentOutput;
    }


    outFile.writeAsStringSync(lastOutput);

    await Future.delayed(Duration(seconds: 1));
  }
}