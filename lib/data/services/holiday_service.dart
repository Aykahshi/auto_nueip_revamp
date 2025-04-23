import 'dart:convert'; // Required for jsonEncode

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/config/api_config.dart';
import '../../core/config/storage_keys.dart'; // Import StorageKeys
import '../../core/network/failure.dart';
import '../../core/utils/local_storage.dart'; // Import LocalStorage
import '../models/holiday.dart'; // Assumes Holiday model has toJson()

class HolidayService {
  final Dio _dio = Dio();

  TaskEither<Failure, List<Holiday>> getHolidays() {
    return TaskEither.tryCatch(
      () async {
        final currentYear = DateTime.now().year;
        // Fetch for previous, current, and next year
        final yearsToFetch = [currentYear - 1, currentYear, currentYear + 1];
        final List<Holiday> allHolidays = [];

        // Loop through each year and fetch data
        for (final year in yearsToFetch) {
          try {
            debugPrint('Fetching holidays for $year...');
            final response = await _dio.get(
              "${ApiConfig.HOLIDAY_URL}/$year.json",
            );
            final List<dynamic> yearData = response.data;
            final List<Holiday> yearHolidays =
                yearData
                    .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
                    .toList();
            allHolidays.addAll(yearHolidays);
            debugPrint('Successfully fetched holidays for $year');
          } catch (e) {
            debugPrint('Error fetching holidays for year $year: $e');
          }
        }

        // Filter the combined list for actual holidays
        final List<Holiday> filteredHolidays =
            allHolidays.where((element) => element.isHoliday).toList();

        debugPrint(
          'Total holidays fetched & filtered across 3 years: ${filteredHolidays.length}',
        );

        // Attempt to serialize and store the filtered list in LocalStorage
        try {
          // Convert List<Holiday> to List<String> using toJson and jsonEncode
          final List<String> holidaysJsonList =
              filteredHolidays
                  .map(
                    (holiday) => jsonEncode(holiday.toJson()),
                  ) // Assumes holiday.toJson() exists
                  .toList();

          // Store the list of JSON strings
          final success = await LocalStorage.set<List<String>>(
            StorageKeys.holidays,
            holidaysJsonList,
          );

          if (success) {
            debugPrint('Successfully stored holidays in LocalStorage.');
          } else {
            debugPrint(
              'Failed to store holidays in LocalStorage (set returned false).',
            );
          }
        } catch (e) {
          debugPrint('Error during holiday serialization or storage: $e');
        }

        return filteredHolidays;
      },
      (error, stackTrace) {
        debugPrint(
          'General error during getHolidays execution: $error\n$stackTrace',
        );
        if (error is DioException) {
          return Failure(
            message:
                error.message ?? 'DioException occurred during holiday fetch',
            status: error.type.toString(),
          );
        }
        return Failure(
          message: 'Failed to fetch holidays: $error',
          status: 'Unknown Error',
        );
      },
    );
  }
}
