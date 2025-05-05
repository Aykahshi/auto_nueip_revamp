import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../data/repositories/holiday_repository_impl.dart';
import '../../domain/entities/holiday_state.dart';
import '../../domain/repositories/holiday_repository.dart';

class HolidayPresenter extends Presenter<HolidayState> {
  final HolidayRepository _repository;

  // Constructor finds the registered HolidayRepository via CircusRing
  HolidayPresenter({HolidayRepository? repository, super.keepAlive = true})
    : _repository = repository ?? Circus.find<HolidayRepositoryImpl>(),
      super(
        const HolidayState.initial(),
      ); // Set initial state using freezed constructor

  /// Fetches the list of holidays for the current year.
  Future<void> fetchHolidays() async {
    // Update state to Loading using the presenter's trick method
    trick(const HolidayState.loading()); // Use freezed constructor

    // Run the repository call
    final result = await _repository.getHolidays().run();

    // Process the result using pattern matching (available with freezed)
    result.match(
      (failure) {
        // On failure, update state to Error
        debugPrint('Error fetching holidays: ${failure.message}');
        trick(HolidayState.error(failure)); // Use freezed constructor
      },
      (holidays) {
        // On success, update state to Success
        debugPrint('Successfully fetched ${holidays.length} holidays.');
        trick(HolidayState.success(holidays)); // Use freezed constructor
      },
    );
  }
}
