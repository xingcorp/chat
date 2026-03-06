import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/update_group_usecase.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/group_avatar_source_bottom_sheet.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/app_dropdown.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/navigation/app_scaffold.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:image_picker/image_picker.dart';

class GroupEditPage extends BaseStatefulWidget {
  final Chat chat;

  const GroupEditPage({
    super.key,
    required this.chat,
  });

  @override
  BaseState<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends BaseState<GroupEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final IAttachmentRepository _attachmentRepository =
      getIt<IAttachmentRepository>();
  final UpdateGroupUseCase _updateGroupUseCase = getIt<UpdateGroupUseCase>();

  Uint8List? _avatarBytes;
  String? _avatarFileName;
  String? _avatarFilePath;
  GroupType _selectedGroupType = GroupType.private;
  bool _isSaving = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.chat.name?.trim() ?? '';
    _descriptionController.text = widget.chat.description?.trim() ?? '';
    _selectedGroupType = widget.chat.groupType ?? GroupType.private;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final errorMessage = context.l10n.errorOccurred;

    try {
      final selectedImage = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (selectedImage == null) return;

      final bytes = await selectedImage.readAsBytes();
      if (bytes.isEmpty) {
        _showMessage(errorMessage, isError: true);
        return;
      }

      safeSetState(() {
        _avatarBytes = bytes;
        _avatarFileName = selectedImage.name.isNotEmpty
            ? selectedImage.name
            : 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        _avatarFilePath =
            selectedImage.path.trim().isNotEmpty ? selectedImage.path : null;
      });
    } catch (_) {
      _showMessage(errorMessage, isError: true);
    }
  }

  Future<void> _showPickAvatarSheet() async {
    final source = await GroupAvatarSourceBottomSheet.show(context);
    if (!mounted || source == null) return;
    await _pickAvatar(source);
  }

  Future<void> _saveGroup() async {
    if (_isSaving) return;

    final newName = _nameController.text.trim();
    final newDescription = _descriptionController.text.trim();
    if (newName.isEmpty) {
      _showMessage(context.l10n.pleaseEnterGroupName, isError: true);
      return;
    }

    final oldName = widget.chat.name?.trim() ?? '';
    final oldDescription = widget.chat.description?.trim() ?? '';
    final hasNameChanged = newName != oldName;
    final hasDescriptionChanged = newDescription != oldDescription;
    final hasGroupTypeChanged =
        _selectedGroupType != (widget.chat.groupType ?? GroupType.private);
    final hasAvatarChanged = _avatarBytes != null;
    if (!hasNameChanged &&
        !hasDescriptionChanged &&
        !hasGroupTypeChanged &&
        !hasAvatarChanged) {
      Navigator.of(context).pop();
      return;
    }

    safeSetState(() {
      _isSaving = true;
      _uploadProgress = null;
    });

    String? uploadedAvatarUrl;
    if (hasAvatarChanged) {
      final avatarBytes = _avatarBytes;
      final avatarFilePath = _avatarFilePath?.trim();
      final canUseFileUpload =
          !kIsWeb && avatarFilePath != null && avatarFilePath.isNotEmpty;

      final uploadResult = await _attachmentRepository.uploadAttachment(
        messageId: 'group-avatar-${widget.chat.id}',
        chatId: widget.chat.id,
        file: canUseFileUpload ? File(avatarFilePath) : null,
        bytes: canUseFileUpload ? null : avatarBytes,
        fileName: _avatarFileName ??
            'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (progress) {
          safeSetState(() => _uploadProgress = progress);
        },
      );

      bool uploadFailed = false;
      uploadResult.fold(
        (failure) {
          uploadFailed = true;
          _showFailure(failure);
        },
        (result) {
          uploadedAvatarUrl = result.url;
        },
      );
      if (uploadFailed) {
        safeSetState(() {
          _isSaving = false;
          _uploadProgress = null;
        });
        return;
      }
    }

    final updateResult = await _updateGroupUseCase(
      UpdateGroupParams(
        conversationId: widget.chat.id,
        name: hasNameChanged ? newName : null,
        imageUrl: hasAvatarChanged ? uploadedAvatarUrl : null,
        description: hasDescriptionChanged ? newDescription : null,
        groupType: hasGroupTypeChanged ? _selectedGroupType : null,
      ),
    );

    if (!mounted) return;

    updateResult.fold(
      (failure) {
        _showFailure(failure);
        safeSetState(() {
          _isSaving = false;
          _uploadProgress = null;
        });
      },
      (updatedChat) {
        try {
          context
              .read<ChatBloc>()
              .add(ChatEvent.chatUpdated(chat: updatedChat));
          context.read<ChatBloc>().add(
                const ChatEvent.loadChats(forceRefresh: true),
              );
        } catch (_) {
          // GroupEditPage can be used in contexts without a shared ChatBloc.
        }
        _showMessage(context.l10n.groupUpdated);
        Navigator.of(context).pop(updatedChat);
      },
    );
  }

  void _showFailure(Failure failure) {
    final message = failure.message.isNotEmpty
        ? failure.message
        : context.l10n.errorOccurred;
    _showMessage(message, isError: true);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (isError) {
      AppSnackBar.error(
        context: context,
        message: message,
      );
      return;
    }

    AppSnackBar.success(
      context: context,
      message: message,
    );
  }

  Widget _buildSelectedAvatar(bool isDark) {
    return InkWell(
      onTap: _isSaving ? null : _showPickAvatarSheet,
      borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
      child: Container(
        width: AppDimens.avatarSizeXLarge,
        height: AppDimens.avatarSizeXLarge,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
            width: AppDimens.dividerThin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          _avatarBytes!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    if (_avatarBytes != null) {
      return _buildSelectedAvatar(isDark);
    }

    final avatarUrl = widget.chat.avatarUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return AppAvatar.network(
        imageUrl: avatarUrl,
        size: AvatarSize.xlarge,
        onTap: _isSaving ? null : _showPickAvatarSheet,
      );
    }

    final fallbackName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : context.l10n.groupName;
    return AppAvatar.initials(
      name: fallbackName,
      size: AvatarSize.xlarge,
      onTap: _isSaving ? null : _showPickAvatarSheet,
      backgroundColor: isDark ? AppColors.primaryDarkMode : AppColors.primary,
      foregroundColor: AppColors.textPrimaryDarkMode,
    );
  }

  List<_GroupTypeOption> _buildGroupTypeOptions(BuildContext context) {
    return <_GroupTypeOption>[
      _GroupTypeOption(
        type: GroupType.private,
        label: context.l10n.privateGroup,
      ),
      _GroupTypeOption(
        type: GroupType.public,
        label: context.l10n.publicGroup,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupTypeOptions = _buildGroupTypeOptions(context);
    final selectedGroupTypeOption = groupTypeOptions.firstWhere(
      (option) => option.type == _selectedGroupType,
      orElse: () => groupTypeOptions.first,
    );

    return AppScaffold(
      appBar: AppBar(
        title: AppText(
          context.l10n.editGroup,
          style: AppTextStyles.titleLarge.copyWith(
            color:
                isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.paddingMedium),
                child: Column(
                  children: [
                    AppCard.outlined(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          const SizedBox(height: AppDimens.spaceMedium),
                          _buildAvatar(isDark),
                          const SizedBox(height: AppDimens.spaceSmall),
                          AppButton.text(
                            text: context.l10n.changePhoto,
                            onPressed: _isSaving ? null : _showPickAvatarSheet,
                          ),
                          if (_uploadProgress != null) ...[
                            const SizedBox(height: AppDimens.spaceSmall),
                            AppProgressIndicator.linear(
                              value: _uploadProgress,
                              label: context.l10n.uploading,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.spaceMedium),
                    AppTextField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.next,
                      label: context.l10n.groupName,
                      prefixIcon: Icons.group_outlined,
                    ),
                    const SizedBox(height: AppDimens.spaceMedium),
                    AppTextField(
                      controller: _descriptionController,
                      enabled: !_isSaving,
                      label: context.l10n.groupDescription,
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 3,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: AppDimens.spaceMedium),
                    AppDropdown<_GroupTypeOption>(
                      items: groupTypeOptions,
                      value: selectedGroupTypeOption,
                      onChanged: _isSaving
                          ? null
                          : (option) {
                              if (option == null) {
                                return;
                              }
                              safeSetState(() {
                                _selectedGroupType = option.type;
                              });
                            },
                      label: context.l10n.groupType,
                      itemBuilder: (option) => AppText(option.label),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              child: AppButton.primary(
                text: context.l10n.save,
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTypeOption {
  final GroupType type;
  final String label;

  const _GroupTypeOption({
    required this.type,
    required this.label,
  });

  @override
  String toString() => label;
}
