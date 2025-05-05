// ignore_for_file: constant_identifier_names

enum ClockAction {
  IN(value: '1'),
  OUT(value: '2');

  const ClockAction({required this.value});

  final String value;
}
