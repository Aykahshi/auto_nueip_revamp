// Adjust the import path to where your Holiday model is defined
import 'package:flutter/foundation.dart';

import '../../data/models/holiday.dart';

extension HolidayListValidation on List<Holiday> {
  /// Checks if the list contains holiday data for the previous and current year.
  /// Assumes holiday.date is a "YYYYMMDD" string.
  bool coversRequiredYears() {
    if (isEmpty) {
      return false;
    }

    final currentYear = DateTime.now().year;
    final requiredYears = {currentYear - 1, currentYear};

    // Efficiently check if holidays exist for each required year
    final Set<int> yearsInData = {};
    for (final holiday in this) {
      // Assuming holiday.date is "YYYYMMDD" string
      if (holiday.date.length >= 4) {
        // Basic check for format validity
        try {
          final year = int.parse(holiday.date.substring(0, 4));
          yearsInData.add(year);
          // Optimization: if all required years are found, no need to check further
          if (yearsInData.containsAll(requiredYears)) {
            return true;
          }
        } catch (e) {
          // Handle potential parsing errors if date format is unexpected
          debugPrint(
            'Error parsing holiday date in extension: ${holiday.date}, error: $e',
          );
          continue; // Skip this holiday
        }
      } else {
        debugPrint(
          'Skipping invalid holiday date format in extension: ${holiday.date}',
        );
      }
    }

    // Check if all required years were present in the data
    return yearsInData.containsAll(requiredYears);
  }
}
