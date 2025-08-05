import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/config/storage_keys.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../data/models/attendance_details.dart';
import '../../domain/entities/attendance_state.dart';

final class AttendancePresenter extends Presenter<AttendanceState> {
  final NueipRepository _repository;
  late final String _userNo;

  AttendancePresenter({super.keepAlive = true})
    : _repository = Circus.find<NueipRepository>(),
      super(const AttendanceState.initial());

  @override
  void onInit() {
    super.onInit();
    _userNo = LocalStorage.get<String>(StorageKeys.userNo, defaultValue: '');
  }

  AttendanceRecord? _dailyAttendanceRecord;
  final Map<String, AttendanceRecord> _attendanceRecords = {};

  Future<void> getAttendanceRecords({
    required String startDate,
    required String endDate,
  }) async {
    final cookie = AuthUtils.getAuthSession().cookie ?? '';

    trick(const AttendanceState.loading());

    final result =
        await _repository
            .getAttendanceRecords(
              startDate: startDate,
              endDate: endDate,
              cookie: cookie,
            )
            .run();

    result.fold((failure) => trick(AttendanceState.error(failure.message)), (
      response,
    ) {
      final jsonData = response.data as Map<String, dynamic>;
      final realData = jsonData['data'] as Map<String, dynamic>;

      _attendanceRecords.clear();

      realData.forEach((date, data) {
        // Check if data for the user exists for this date
        if (data is Map<String, dynamic> && data.containsKey(_userNo)) {
          final detail = data[_userNo];
          // Ensure detail is a Map before parsing
          if (detail is Map<String, dynamic>) {
            try {
              _attendanceRecords.addAll({
                date: AttendanceRecord.fromJson(detail),
              });
            } catch (e) {
              debugPrint("Error parsing AttendanceRecord for date $date: $e");
              // Optionally add a placeholder or skip this record
            }
          } else {
            debugPrint("Invalid detail format for date $date: $detail");
          }
        } else {
          debugPrint(
            "No data found for user $_userNo on date $date or invalid data structure.",
          );
          // Optionally add an empty/placeholder record for this date
          // _attendanceRecords.addAll({date: AttendanceRecord(/* default values */)});
        }
      });

      trick(AttendanceState.success(_attendanceRecords, null));
    });
  }

  Future<void> getDailyAttendanceRecord({required String date}) async {
    final cookie = AuthUtils.getAuthSession().cookie ?? '';

    trick(const AttendanceState.loading());

    final result =
        await _repository
            .getDailyAttendanceRecord(date: date, cookie: cookie)
            .run();

    result.fold((failure) => trick(AttendanceState.error(failure.message)), (
      response,
    ) {
      final jsonData = response.data as Map<String, dynamic>;
      final realData = jsonData['data'] as Map<String, dynamic>;

      final detail = (realData[date] as Map<String, dynamic>)[_userNo];

      _dailyAttendanceRecord = AttendanceRecord.fromJson(detail);

      trick(AttendanceState.success({}, _dailyAttendanceRecord));
    });
  }

  Future<void> refresh() async {
    reset();

    await getDailyAttendanceRecord(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }

  void reset() {
    _dailyAttendanceRecord = null;
    _attendanceRecords.clear();
    trick(const AttendanceState.initial());
  }
}
