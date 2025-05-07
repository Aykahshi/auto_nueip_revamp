import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/network/failure.dart';
import '../../../calendar/presentation/widgets/detail_info_row.dart';
import '../../data/models/form_type_enum.dart';
import '../../data/models/leave_record.dart';
import '../../data/models/leave_sign_data.dart';
import '../presenters/sign_presenter.dart';
import 'image_preview_dialog.dart';

/// Displays the detailed view for a leave form, including sign process.
class LeaveFormDetails extends StatefulWidget {
  final LeaveRecord leaveRecord;

  const LeaveFormDetails({super.key, required this.leaveRecord});

  @override
  State<LeaveFormDetails> createState() => _LeaveFormDetailsState();
}

class _LeaveFormDetailsState extends State<LeaveFormDetails> {
  // Create and hold the SignPresenter instance
  late final SignPresenter _signPresenter;
  // Debouncer for the delete action
  final _deleteDebouncer = CueGate.debounce(
    delay: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    _signPresenter = Circus.find<SignPresenter>();
    _signPresenter.fetchSignData(FormType.leave, widget.leaveRecord.id);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- Moved LeaveRecord Helpers ---
  Color _getLeaveStatusColor(num signStatus, BuildContext context) {
    if (signStatus == 2) return Colors.green.shade600; // Approved
    if (signStatus == 3) return context.colorScheme.error; // Rejected
    return Colors.orange.shade700; // Pending or other
  }

  String _getLeaveStatusText(num signStatus) {
    if (signStatus == 2) return '已核准';
    if (signStatus == 3) return '已駁回';
    if (signStatus < 2) return '簽核中';
    return '未知狀態';
  }

  String _formatLeaveTimestamp(String? timeStr) {
    if (timeStr == null) return '--';
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(timeStr);
      return DateFormat('yyyy/MM/dd HH:mm').format(dt);
    } catch (e) {
      return '格式錯誤';
    }
  }

  // --- New Helper for Stepper Subtitle Rows ---
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    Color? iconColor,
  }) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final effectiveValueColor = valueColor ?? colorScheme.onSurface;
    final effectiveIconColor =
        iconColor ?? colorScheme.secondary.withValues(alpha: 0.8);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.h(1.5)),
            child: Icon(icon, size: context.r(14), color: effectiveIconColor),
          ),
          Gap(context.w(8)),
          Text(
            '$label: ',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
              fontSize: context.sp(12),
              height: 1.45,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                color: effectiveValueColor,
                fontSize: context.sp(12),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }
  // --- End New Helper ---

  List<Step> _buildStepperSteps(
    BuildContext context,
    LeaveSignData? signData,
    num overallSignStatus,
  ) {
    if (signData == null) {
      return [
        const Step(
          title: Text('簽核流程'),
          content: SizedBox.shrink(),
          subtitle: Text('載入中...'),
          state: StepState.indexed,
          isActive: true,
        ),
      ];
    }

    final steps = <Step>[];
    final auditList = signData.auditList;
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    final submitTimeFormatted = _formatLeaveTimestamp(
      widget.leaveRecord.createTime,
    );
    steps.add(
      Step(
        title: Text(
          '申請提交',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '於 $submitTimeFormatted 提出申請',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        content: const SizedBox.shrink(),
        isActive: true,
        state: StepState.complete,
      ),
    );

    bool isRejectedFound = false;
    for (int i = 0; i < auditList.length; i++) {
      final item = auditList[i];
      StepState state;
      bool isActive;
      List<Widget> detailRows = [];

      String signerName;

      signerName = '簽核人 ${item.roundNo ?? i + 1}';

      if (item.managerName != null && item.managerName!.isNotEmpty) {
        signerName = item.managerName!;
      } else
      // If signManagerName is available, replace signManagerName
      if (item.signManagerName != null && item.signManagerName!.isNotEmpty) {
        signerName = item.signManagerName!;
      }

      final signTimeFormatted = _formatLeaveTimestamp(item.signTime);

      if (item.replyStatus == 3) {
        state = StepState.error;
        isActive = true;
        isRejectedFound = true;
        detailRows.add(
          _buildDetailRow(
            Icons.cancel_outlined,
            '狀態',
            '已駁回',
            valueColor: colorScheme.error,
            iconColor: colorScheme.error,
          ),
        );
        if (signTimeFormatted != '--') {
          detailRows.add(
            _buildDetailRow(Icons.access_time, '時間', signTimeFormatted),
          );
        }
        if (item.replyRemark != null && item.replyRemark!.isNotEmpty) {
          detailRows.add(
            _buildDetailRow(
              Icons.report_problem_outlined,
              '原因',
              item.replyRemark!,
              valueColor: colorScheme.error,
            ),
          );
        }
      } else if (item.isSigned) {
        state = StepState.complete;
        isActive = true;
        detailRows.add(
          _buildDetailRow(
            Icons.check_circle_outline,
            '狀態',
            '已簽核',
            valueColor: colorScheme.primary,
            iconColor: colorScheme.primary,
          ),
        );
        if (signTimeFormatted != '--') {
          detailRows.add(
            _buildDetailRow(Icons.access_time, '時間', signTimeFormatted),
          );
        }
        if (item.replyRemark != null && item.replyRemark!.isNotEmpty) {
          detailRows.add(
            _buildDetailRow(Icons.notes_outlined, '備註', item.replyRemark!),
          );
        }
        if (item.addedRemark != null && item.addedRemark!.isNotEmpty) {
          detailRows.add(
            _buildDetailRow(
              Icons.add_comment_outlined,
              '加註',
              item.addedRemark!,
            ),
          );
        }
      } else {
        if (isRejectedFound) {
          state = StepState.disabled;
          isActive = false;
          detailRows.add(
            _buildDetailRow(
              Icons.remove_circle_outline,
              '狀態',
              '-',
              valueColor: colorScheme.outline.withValues(alpha: 0.6),
            ),
          );
        } else {
          final currentProcessingStepIndex = signData.currentState.toInt();
          final stepIndexInAuditList = i + 1;
          if (stepIndexInAuditList == currentProcessingStepIndex) {
            state = StepState.indexed;
            isActive = true;
            detailRows.add(
              _buildDetailRow(
                Icons.pending_outlined,
                '狀態',
                '待簽核',
                valueColor: colorScheme.tertiary,
                iconColor: colorScheme.tertiary,
              ),
            );
          } else {
            state = StepState.disabled;
            isActive = false;
            detailRows.add(
              _buildDetailRow(
                Icons.pending_outlined,
                '狀態',
                '待簽核',
                valueColor: colorScheme.outline.withValues(alpha: 0.6),
              ),
            );
          }
        }
      }

      if (isRejectedFound && state != StepState.error) {
        isActive = false;
        state = StepState.disabled;
      }
      if (!isActive && state == StepState.complete) {
        isActive = true;
      }

      steps.add(
        Step(
          title: Text(
            signerName,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle:
              detailRows.isEmpty
                  ? null
                  : Container(
                    margin: EdgeInsets.only(top: context.h(4)),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(8),
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: detailRows,
                    ),
                  ),
          content: const SizedBox.shrink(),
          isActive: isActive,
          state: state,
        ),
      );
    }

    return steps;
  }

  // Section title helper
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: context.sp(14),
        ),
      ),
    );
  }
  // --- End Moved Helpers ---

  @override
  Widget build(BuildContext context) {
    return _signPresenter.perform(
      builder: (context, state) {
        final record = widget.leaveRecord;
        final formId = record.qryNo;
        final currentTheme = context.theme;
        final colorScheme = context.colorScheme;

        final overallStatusColor = _getLeaveStatusColor(
          record.signStatus,
          context,
        );
        final overallStatusText = _getLeaveStatusText(record.signStatus);

        final signData = state.signData;
        final isLoadingSignData = state.isLoading;
        final signError = state.error;

        final steps = _buildStepperSteps(context, signData, record.signStatus);

        int currentProcessStepIndex = steps.indexWhere(
          (step) => step.state != StepState.complete,
        );
        if (currentProcessStepIndex == -1) {
          final lastActiveIndex = steps.lastIndexWhere((step) => step.isActive);
          currentProcessStepIndex =
              lastActiveIndex >= 0 ? lastActiveIndex : steps.length - 1;
        } else if (steps[currentProcessStepIndex].state == StepState.disabled &&
            currentProcessStepIndex > 0) {
          final lastActiveIndex = steps.lastIndexWhere(
            (step) => step.isActive,
            currentProcessStepIndex - 1,
          );
          currentProcessStepIndex = lastActiveIndex >= 0 ? lastActiveIndex : 0;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(context.i(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '基本資訊'),
              DetailInfoRow(
                icon: Icons.person_outline,
                label: '申請人',
                value: record.username ?? '未知',
              ),
              DetailInfoRow(
                icon: Icons.category_outlined,
                label: '假別',
                value: record.ruleName ?? '未知',
              ),
              DetailInfoRow(
                icon: Icons.receipt_long_outlined,
                label: '表單編號',
                value: formId,
              ),
              DetailInfoRow(
                icon: Icons.date_range_outlined,
                label: '請假時間',
                value:
                    '${_formatLeaveTimestamp(record.startTime)}\n${_formatLeaveTimestamp(record.endTime)}',
                maxLines: null,
              ),
              DetailInfoRow(
                icon: Icons.edit_calendar_outlined,
                label: '申請時間',
                value: _formatLeaveTimestamp(record.createTime),
              ),
              DetailInfoRow(
                icon: Icons.hourglass_empty,
                label: '總時數',
                value: record.formattedTotalHours,
              ),
              if (record.agentName != null && record.agentName!.isNotEmpty)
                DetailInfoRow(
                  icon: Icons.support_agent,
                  label: '代理人',
                  value: record.agentName!,
                ),
              DetailInfoRow(
                icon: Icons.info_outline,
                label: '目前狀態',
                value: overallStatusText,
                valueColor: overallStatusColor,
              ),
              if (record.remark != null && record.remark!.isNotEmpty)
                DetailInfoRow(
                  icon: Icons.notes,
                  label: '事由說明',
                  value: record.remark!,
                  maxLines: null,
                ),
              Gap(context.h(16)),

              if (record.fileInfo?.storage != null &&
                  record.fileInfo!.storage!.isNotEmpty) ...[
                _buildSectionTitle(context, '附件'),
                ...record.fileInfo!.storage!.map((file) {
                  final imageUrl =
                      (file.link != null && file.link!.startsWith('/'))
                          ? '${ApiConfig.BASE_URL}${file.link}'
                          : file.link;
                  return DetailInfoRow(
                    icon: Icons.attach_file,
                    label: file.name ?? '未命名檔案',
                    value: '點擊預覽',
                    isLink: true,
                    onTap:
                        imageUrl != null
                            ? () {
                              showDialog(
                                context: context,
                                builder:
                                    (_) =>
                                        ImagePreviewDialog(imageUrl: imageUrl),
                              );
                            }
                            : null,
                  );
                }),
                Gap(context.h(16)),
              ],

              _buildSectionTitle(context, '簽核流程'),
              if (isLoadingSignData)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.h(20)),
                    child: const CircularProgressIndicator(),
                  ),
                )
              else if (signError != null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.h(20)),
                    child: Text(
                      '無法載入簽核流程: $signError',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                )
              else
                Theme(
                      data: currentTheme.copyWith(
                        colorScheme: colorScheme.copyWith(
                          primary: colorScheme.primary,
                          onSurface: colorScheme.onSurfaceVariant,
                          surface: Colors.transparent,
                          onSurfaceVariant: colorScheme.outline,
                          error: colorScheme.error,
                        ),
                        canvasColor: currentTheme.canvasColor,
                        // Disable splash effect for Stepper steps
                        splashFactory: NoSplash.splashFactory,
                        highlightColor:
                            Colors.transparent, // Also remove highlight effect
                      ),
                      child: Stepper(
                        steps: steps,
                        currentStep: currentProcessStepIndex,
                        type: StepperType.vertical,
                        controlsBuilder: (context, details) => Container(),
                        physics: const NeverScrollableScrollPhysics(),
                        margin: EdgeInsets.zero,
                        stepIconBuilder: (stepIndex, stepState) {
                          Color iconFgColor;
                          Color iconBgColor;
                          IconData iconData;
                          double iconSize = context.r(14);
                          double circleRadius = context.r(12);

                          switch (stepState) {
                            case StepState.indexed:
                            case StepState.editing:
                              iconFgColor = colorScheme.onPrimary;
                              iconBgColor = colorScheme.primary;
                              iconData = Icons.edit_outlined;
                              break;
                            case StepState.complete:
                              iconFgColor = colorScheme.onPrimary;
                              iconBgColor = colorScheme.primary;
                              iconData = Icons.check_rounded;
                              break;
                            case StepState.error:
                              iconFgColor = colorScheme.onError;
                              iconBgColor = colorScheme.error;
                              iconData = Icons.close_rounded;
                              break;
                            case StepState.disabled:
                              iconFgColor = colorScheme.outline.withValues(
                                alpha: 0.7,
                              );
                              iconBgColor = colorScheme.surfaceContainerHighest;
                              iconData = Icons.circle_outlined;
                              break;
                          }
                          return CircleAvatar(
                            radius: circleRadius,
                            backgroundColor: iconBgColor,
                            child: Icon(
                              iconData,
                              color: iconFgColor,
                              size: iconSize,
                            ),
                          );
                        },
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, curve: Curves.easeInOut),

              if (record.canCancel) ...[
                Gap(context.h(20)),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('撤銷申請'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      backgroundColor: colorScheme.errorContainer.withValues(
                        alpha: 0.4,
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(16),
                        vertical: context.h(10),
                      ),
                    ),
                    onPressed: () {
                      showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Center(child: Text('確認撤銷申請')),
                            content: const Text(
                              '您確定要撤銷此假單申請嗎？\n此操作無法復原。',
                              textAlign: TextAlign.center,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('取消'),
                                onPressed: () {
                                  dialogContext.router.pop(false);
                                },
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      dialogContext.colorScheme.error,
                                ),
                                child: const Text('確定撤銷'),
                                onPressed: () {
                                  dialogContext.router.pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      ).then((confirmed) {
                        if (mounted && confirmed == true) {
                          _deleteDebouncer.trigger(() {
                            // Use the instance's trigger method
                            if (!mounted) return;
                            _signPresenter.deleteLeaveForm(
                              id: record.id,
                              onSuccess: () {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('假單已成功撤銷')),
                                  );
                                  context.router.pop();
                                }
                              },
                              onFailed: () {
                                if (mounted) {
                                  String errorMessage = '撤銷失敗，請稍後再試';
                                  final dynamic errorValue =
                                      _signPresenter.state.error;
                                  if (errorValue is Failure) {
                                    errorMessage = errorValue.message;
                                  } else if (errorValue is String &&
                                      errorValue.isNotEmpty) {
                                    errorMessage = errorValue;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor:
                                          context.colorScheme.error,
                                    ),
                                  );
                                }
                              },
                            );
                          });
                        }
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
      },
    );
  }
}
