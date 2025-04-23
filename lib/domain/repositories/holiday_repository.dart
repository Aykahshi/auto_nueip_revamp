import 'package:fpdart/fpdart.dart';

import '../../core/network/failure.dart';
import '../../data/models/holiday.dart'; // Corrected path

abstract class HolidayRepository {
  TaskEither<Failure, List<Holiday>> getHolidays();
}
