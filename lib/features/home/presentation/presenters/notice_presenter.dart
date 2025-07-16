import 'package:joker_state/joker_state.dart';

import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../domain/entities/notice_state.dart';

final class NoticePresenter extends Presenter<NoticeState> {
  NoticePresenter()
    : _repository = Circus.find<NueipRepository>(),
      super(NoticeState.initial());

  final NueipRepository _repository;
  int _page = 1;

  @override
  void onReady() async {
    super.onReady();
    await fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading) return;

    trickWith((state) => state.copyWith(isLoading: true));

    final result = await _repository.getNoticeList(_page).run();

    result.fold(
      (failure) => trickWith(
        (state) => state.copyWith(isLoading: false, failure: failure),
      ),
      (noticeList) {
        trickWith(
          (state) => state.copyWith(
            isLoading: false,
            notices: [...state.notices, ...noticeList],
          ),
        );
        if (noticeList.isNotEmpty) {
          _page++;
        }
      },
    );
  }

  Future<void> refresh() async {
    _page = 1;
    trickWith((state) => state.copyWith(notices: [], isLoading: true));

    final result = await _repository.getNoticeList(_page).run();

    result.fold(
      (failure) => trickWith(
        (state) => state.copyWith(isLoading: false, failure: failure),
      ),
      (noticeList) {
        trickWith(
          (state) => state.copyWith(isLoading: false, notices: noticeList),
        );
        if (noticeList.isNotEmpty) {
          _page++;
        }
      },
    );
  }
}
