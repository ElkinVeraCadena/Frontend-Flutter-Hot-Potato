import 'dart:io';
import 'dart:convert';

void main() async {
  final result = await Process.run('flutter', ['analyze', '--machine']);
  final File file = File('analysis_machine.json');
  file.writeAsStringSync(result.stdout);
  print('Done');
}
