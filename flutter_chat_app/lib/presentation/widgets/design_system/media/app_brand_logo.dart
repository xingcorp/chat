import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/config/app_identity.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';

enum AppBrandLogoVariant {
  icon,
  wordmark,
}

class AppBrandLogo extends BaseStatelessWidget {
  const AppBrandLogo({
    this.variant = AppBrandLogoVariant.wordmark,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    super.key,
  });

  const AppBrandLogo.icon({
    double? size,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Key? key,
  }) : this(
          variant: AppBrandLogoVariant.icon,
          width: size,
          height: size,
          fit: fit,
          borderRadius: borderRadius,
          key: key,
        );

  const AppBrandLogo.wordmark({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Key? key,
  }) : this(
          variant: AppBrandLogoVariant.wordmark,
          width: width,
          height: height,
          fit: fit,
          key: key,
        );

  final AppBrandLogoVariant variant;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget buildContent(BuildContext context) {
    return AppImage.asset(
      assetPath: _assetPath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  String get _assetPath {
    switch (variant) {
      case AppBrandLogoVariant.icon:
        return AppIdentity.appIconPath;
      case AppBrandLogoVariant.wordmark:
        return AppIdentity.logoPath;
    }
  }
}
