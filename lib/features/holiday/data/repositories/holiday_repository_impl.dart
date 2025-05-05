import 'package:fpdart/fpdart.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/network/failure.dart';
import '../../domain/repositories/holiday_repository.dart';
import '../models/holiday.dart';
import '../services/holiday_service.dart';

final class HolidayRepositoryImpl implements HolidayRepository {
  final HolidayService _holidayService;

  HolidayRepositoryImpl({HolidayService? holidayService})
    : _holidayService = Circus.find<HolidayService>();

  @override
  TaskEither<Failure, List<Holiday>> getHolidays() {
    return _holidayService.getHolidays();
  }
}
