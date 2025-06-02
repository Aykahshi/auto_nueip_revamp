import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/apis.dart';
import '../../../../core/config/storage_keys.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/utils/local_storage.dart';
import '../models/holiday.dart';

// --- Top-level function for Isolate execution ---
Future<List<Holiday>> _fetchAndParseHolidaysForYear(int year) async {
  // Create a new Dio instance within the isolate
  final dio = Dio();
  try {
    debugPrint('[Isolate] Fetching holidays for $year...');
    final response = await dio.get<List<dynamic>>("${APIs.HOLIDAY}/$year.json");
    // Ensure response.data is not null before proceeding
    final responseData = response.data;
    if (responseData == null) {
      debugPrint('[Isolate] No data received for year $year.');
      return []; // Return empty list if data is null
    }

    // Parse JSON - this happens in the isolate
    final List<Holiday> yearHolidays =
        responseData
            .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
            .toList();
    debugPrint('[Isolate] Successfully parsed holidays for $year');
    return yearHolidays;
  } catch (e) {
    // Catch errors within the isolate and print
    debugPrint('[Isolate] Error fetching/parsing holidays for year $year: $e');
    // Propagate the error or return an empty list depending on desired handling
    // Returning empty list here to allow other years to potentially succeed.
    return [];
  }
}
// --- End of Isolate function ---

final class HolidayService {
  void _addLaborDayHoliday(List<Holiday> holidays, int year) {
    final laborDay = '$year-05-01';

    final existingHoliday = holidays.any((holiday) => holiday.date == laborDay);

    if (!existingHoliday) {
      holidays.add(
        Holiday(date: laborDay, isHoliday: true, description: '勞動節補休'),
      );
      debugPrint('已添加 $year 年勞動節補休假期');
    }
  }

  TaskEither<Failure, List<Holiday>> getHolidays() {
    return TaskEither.tryCatch(
      () async {
        final currentYear = DateTime.now().year;
        // Modify the years to fetch: only current and previous year
        final yearsToFetch = [currentYear - 1, currentYear];
        final List<Future<List<Holiday>>> fetchFutures = [];

        debugPrint(
          'Spawning isolates to fetch holidays for years: $yearsToFetch',
        );
        // Spawn compute for each year
        for (final year in yearsToFetch) {
          // Use compute to run _fetchAndParseHolidaysForYear in an isolate
          fetchFutures.add(compute(_fetchAndParseHolidaysForYear, year));
        }

        // Wait for all isolates to complete
        final List<List<Holiday>> results = await Future.wait(fetchFutures);

        // Combine results from all isolates
        final List<Holiday> allHolidays =
            results.expand((list) => list).toList();

        // Filter the combined list for actual holidays (on main thread)
        final List<Holiday> filteredHolidays =
            allHolidays.where((element) => element.isHoliday).toList();

        // 添加當年度的 5/1 勞動節補休假期
        _addLaborDayHoliday(filteredHolidays, currentYear);

        debugPrint(
          'Total holidays fetched & filtered across 2 years: ${filteredHolidays.length}',
        );

        // Attempt to serialize and store (on main thread)
        try {
          final List<String> holidaysJsonList =
              filteredHolidays
                  .map((holiday) => jsonEncode(holiday.toJson()))
                  .toList();

          final success = await LocalStorage.set<List<String>>(
            StorageKeys.holidays,
            holidaysJsonList,
          );

          if (success) {
            debugPrint('Successfully stored holidays in LocalStorage.');
          } else {
            debugPrint('Failed to store holidays in LocalStorage.');
          }
        } catch (e) {
          debugPrint('Error during holiday serialization or storage: $e');
          // Decide if this error should fail the whole operation
          // For now, we proceed returning the fetched data even if storage fails
        }

        return filteredHolidays;
      },
      (error, stackTrace) {
        // This catches errors from Future.wait (if an isolate failed badly)
        // or other errors in the main thread part of the async function.
        debugPrint(
          'General error during getHolidays execution: $error\n$stackTrace',
        );
        // Keep existing error handling for DioExceptions or other types
        if (error is DioException) {
          return Failure(
            message:
                error.message ?? 'DioException occurred during holiday fetch',
            status: error.type.toString(),
          );
        }
        if (error is MissingPluginException) {
          debugPrint(
            'Compute failed: Missing plugin? Ensure platform integration is correct.',
          );
          return const Failure(
            message: '背景處理失敗，請檢查應用程式設定。',
            status: 'Compute Error',
          );
        }
        return Failure(message: '無法獲取假日資料: $error', status: 'Unknown Error');
      },
    );
  }
}
