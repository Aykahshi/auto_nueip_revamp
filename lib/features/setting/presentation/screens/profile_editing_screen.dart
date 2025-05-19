import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../domain/entities/profile_editing_state.dart';
import '../presenters/profile_editing_presenter.dart';

@RoutePage()
class ProfileEditingScreen extends StatefulWidget {
  const ProfileEditingScreen({super.key});

  @override
  State<ProfileEditingScreen> createState() => _ProfileEditingScreenState();
}

class _ProfileEditingScreenState extends State<ProfileEditingScreen> {
  late final ProfileEditingPresenter _presenter;
  late final GlobalKey<FormBuilderState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormBuilderState>();
    _presenter = ProfileEditingPresenter();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showErrorMessage(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colorScheme.error,
      ),
    );
  }

  void _handleSave(ProfileEditingState currentState) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      _presenter.saveProfile(
        values['companyCode'],
        values['employeeId'],
        values['password'],
        values['companyAddress'],
      );
    } else {
      _showErrorMessage('請檢查輸入欄位');
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colorScheme.primary;

    return _presenter.effect(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('編輯帳號資訊'),
          leading: const AutoLeadingButton(),
          centerTitle: true,
          elevation: 1,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(16),
            ),
            child: _presenter.perform(
              builder: (context, state) {
                return IgnorePointer(
                  ignoring: state.isLoading,
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: {
                      'companyCode': state.companyCode,
                      'employeeId': state.employeeId,
                      'password': state.password,
                      'companyAddress': state.companyAddress,
                    },
                    enabled: state.isEditing,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      context.r(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: context.h(16),
                                      horizontal: context.w(16),
                                    ),
                                    child: Column(
                                      children: [
                                        FormBuilderTextField(
                                              name: 'companyCode',
                                              decoration: const InputDecoration(
                                                labelText: '公司代碼',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.business_outlined,
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator:
                                                  FormBuilderValidators.compose([
                                                    FormBuilderValidators.required(
                                                      errorText: '請輸入公司代碼',
                                                    ),
                                                    FormBuilderValidators.numeric(
                                                      errorText: '公司代碼只能包含數字',
                                                    ),
                                                  ]),
                                              onTapOutside:
                                                  (e) =>
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus(),
                                            )
                                            .animate()
                                            .fadeIn(duration: 300.ms)
                                            .slideX(
                                              begin: -0.1,
                                              duration: 300.ms,
                                              curve: Curves.easeOutQuart,
                                            ),
                                        Gap(context.h(20)),
                                        FormBuilderTextField(
                                              name: 'employeeId',
                                              decoration: const InputDecoration(
                                                labelText: '員工編號',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.badge_outlined,
                                                ),
                                              ),
                                              validator:
                                                  FormBuilderValidators.required(
                                                    errorText: '請輸入員工編號',
                                                  ),
                                              onTapOutside:
                                                  (e) =>
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus(),
                                            )
                                            .animate()
                                            .fadeIn(
                                              duration: 300.ms,
                                              delay: 50.ms,
                                            )
                                            .slideX(
                                              begin: -0.1,
                                              duration: 300.ms,
                                              curve: Curves.easeOutQuart,
                                              delay: 50.ms,
                                            ),
                                        Gap(context.h(20)),
                                        FormBuilderTextField(
                                              name: 'password',
                                              decoration: InputDecoration(
                                                labelText: '密碼',
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: const Icon(
                                                  Icons.lock_outline,
                                                ),
                                                suffixIcon:
                                                    state.isEditing
                                                        ? IconButton(
                                                          icon: Icon(
                                                            state.isPasswordVisible
                                                                ? Icons
                                                                    .visibility_off
                                                                : Icons
                                                                    .visibility,
                                                            color: iconColor,
                                                          ),
                                                          onPressed:
                                                              _presenter
                                                                  .togglePasswordVisibility,
                                                        )
                                                        : null,
                                              ),
                                              obscureText:
                                                  !state.isPasswordVisible,
                                              keyboardType:
                                                  TextInputType.visiblePassword,
                                              validator:
                                                  FormBuilderValidators.required(
                                                    errorText: '請輸入密碼',
                                                  ),
                                              onTapOutside:
                                                  (e) =>
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus(),
                                            )
                                            .animate()
                                            .fadeIn(
                                              duration: 300.ms,
                                              delay: 100.ms,
                                            )
                                            .slideX(
                                              begin: -0.1,
                                              duration: 300.ms,
                                              curve: Curves.easeOutQuart,
                                              delay: 100.ms,
                                            ),
                                        Gap(context.h(20)),
                                        FormBuilderTextField(
                                              name: 'companyAddress',
                                              decoration: InputDecoration(
                                                labelText: '公司地址',
                                                hintText: '請輸入公司詳細地址',
                                                hintStyle: context
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: context
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    ),
                                                helperText:
                                                    '請輸入公司詳細地址，APP 會為您自動轉換成經緯度',
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: const Icon(
                                                  Icons.location_on_outlined,
                                                ),
                                              ),

                                              validator:
                                                  FormBuilderValidators.required(
                                                    errorText: '請輸入公司詳細地址',
                                                  ),
                                              onTapOutside:
                                                  (e) =>
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus(),
                                            )
                                            .animate()
                                            .fadeIn(
                                              duration: 300.ms,
                                              delay: 150.ms,
                                            )
                                            .slideX(
                                              begin: -0.1,
                                              duration: 300.ms,
                                              curve: Curves.easeOutQuart,
                                              delay: 150.ms,
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                                Gap(context.h(30)),
                              ],
                            ),
                          ),
                        ),
                        ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(
                                  double.infinity,
                                  context.h(52),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    context.r(12),
                                  ),
                                ),
                                elevation: 3,
                              ),
                              onPressed: () {
                                if (state.isEditing) {
                                  _handleSave(state);
                                } else {
                                  _presenter.toggleEditing();
                                }
                              },
                              child:
                                  state.isLoading
                                      ? SizedBox(
                                        width: context.w(24),
                                        height: context.h(24),
                                        child: CircularProgressIndicator(
                                          color: context.colorScheme.onPrimary,
                                          strokeWidth: context.w(3),
                                        ),
                                      )
                                      : Text(
                                        state.isEditing ? '儲存變更' : '編輯資訊',
                                        style: TextStyle(
                                          fontSize: context.sp(18),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 500.ms)
                            .slideY(
                              begin: 0.3,
                              duration: 400.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      effect: (BuildContext context, ProfileEditingState state) {
        // Show error message if any
        if (state.error != null) {
          _showErrorMessage(state.error!);
        }
        // Reset form fields if editing is toggled off after saving
        if (!state.isEditing && state.error == null) {
          _formKey.currentState?.patchValue({
            'companyCode': state.companyCode,
            'employeeId': state.employeeId,
            'password': state.password,
            'companyAddress': state.companyAddress,
          });
        }
      },
    );
  }
}
