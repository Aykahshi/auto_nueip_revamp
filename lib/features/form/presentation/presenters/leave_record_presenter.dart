import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/config/storage_keys.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../nueip/data/models/user_sn.dart';
import '../../../nueip/data/repositories/nueip_repository_impl.dart';
import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../domain/entities/leave_record_state.dart';

class LeaveRecordPresenter extends Presenter<LeaveRecordState> {
  final NueipRepository _repository;

  LeaveRecordPresenter({NueipRepository? repository, super.keepAlive = true})
    : _repository = repository ?? Circus.find<NueipRepositoryImpl>(),
      super(const LeaveRecordState.initial());

  Future<void> fetchLeaveRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (startDate == null || endDate == null) {
      trick(const LeaveRecordState.initial());
      return;
    }

    trick(const LeaveRecordState.loading());

    final result =
        await TaskEither<Failure, LeaveRecordState>.Do(($) async {
          String? employee;

          // 1. Try getting UserSn from LocalStorage
          final cookie = AuthUtils.getAuthSession().cookie ?? '';

          try {
            final userSn = LocalStorage.get<List<String>>(
              StorageKeys.userSn,
              defaultValue: [],
            );
            if (userSn.isNotEmpty) {
              final sn = UserSn(
                company: userSn[0],
                department: userSn[1],
                system: userSn[2],
              );
              employee = '${sn.company}_${sn.department}_${sn.system}';
            }
          } catch (e) {
            await LocalStorage.remove(StorageKeys.userSn);
          }

          // 2. If not found in storage, fetch from API
          if (employee == null) {
            final sn = await $(_repository.getUserSn());

            // Check if system SN is valid
            if (sn.system.isEmpty) {
              await $(
                TaskEither<Failure, dynamic>.left(
                  const Failure(message: '從 API 獲取的使用者 SN 無效', status: '400'),
                ),
              );
            }
            employee = '${sn.company}_${sn.department}_${sn.system}';
          }

          // 3. Get leave records using the obtained SN
          final records = await $(
            _repository.getLeaveRecords(
              employee: employee,
              startDate: DateFormat('yyyy-MM-dd').format(startDate),
              endDate: DateFormat('yyyy-MM-dd').format(endDate),
              cookie: cookie,
            ),
          );

          // 4. Return success state
          return LeaveRecordState.success(records: records);
        }).run();

    result.match(
      (failure) => trick(LeaveRecordState.error(failure: failure)),
      (successState) => trick(successState),
    );
  }

  void reset() {
    trick(const LeaveRecordState.initial());
  }
}
