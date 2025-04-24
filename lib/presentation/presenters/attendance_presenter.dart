import 'package:joker_state/joker_state.dart';

import '../../core/config/storage_keys.dart';
import '../../core/utils/auth_utils.dart';
import '../../core/utils/local_storage.dart';
import '../../data/models/attendance_details.dart';
import '../../data/repositories/nueip_repository_impl.dart';
import '../../domain/entities/attendance_state.dart';
import '../../domain/repositories/nueip_repository.dart';

class AttendancePresenter extends Presenter<AttendanceState> {
  final NueipRepository _repository;
  late final String _userNo;

  AttendancePresenter()
    : _repository = Circus.find<NueipRepositoryImpl>(),
      super(const AttendanceState.initial());

  @override
  void onInit() {
    super.onInit();
    _userNo = LocalStorage.get<String>(StorageKeys.userNo, defaultValue: '');
  }

  AttendanceRecord? _dailyAttendanceRecord;
  final List<AttendanceRecord> _attendanceRecords = [];

  Future<void> getAttendanceRecords({
    required String startDate,
    required String endDate,
  }) async {
    final cookie = AuthUtils.getAuthSession().cookie ?? '';

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

      realData.forEach((_, data) {
        final detail = (data as Map<String, dynamic>)[_userNo];
        _attendanceRecords.add(AttendanceRecord.fromJson(detail));
      });

      trick(AttendanceState.success(_attendanceRecords, null));
    });
  }

  Future<void> getDailyAttendanceRecord({required String date}) async {
    final cookie = AuthUtils.getAuthSession().cookie ?? '';

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

      trick(AttendanceState.success([], _dailyAttendanceRecord));
    });
  }

  void reset() {
    _dailyAttendanceRecord = null;
    _attendanceRecords.clear();
  }
}
