import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A reusable Lottie animation widget for BayNavigator.
///
/// Usage:
/// ```dart
/// // From assets
/// LottieAnimation.asset('assets/animations/loading.json')
///
/// // With configuration
/// LottieAnimation.asset(
///   'assets/animations/success.json',
///   repeat: false,
///   width: 100,
///   height: 100,
/// )
///
/// // From URL
/// LottieAnimation.network('https://example.com/animation.json')
///
/// // Using presets
/// LottieAnimation.preset(LottiePreset.loading)
/// ```
class LottieAnimation extends StatelessWidget {
  final String? assetPath;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool reverse;
  final double? speed;
  final void Function(LottieComposition)? onLoaded;
  final Widget Function(BuildContext, Widget, LottieComposition?)? frameBuilder;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const LottieAnimation._({
    this.assetPath,
    this.networkUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.reverse = false,
    this.speed,
    this.onLoaded,
    this.frameBuilder,
    this.errorWidget,
    this.loadingWidget,
    super.key,
  });

  /// Create a Lottie animation from an asset file.
  factory LottieAnimation.asset(
    String assetPath, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool reverse = false,
    double? speed,
    void Function(LottieComposition)? onLoaded,
    Widget Function(BuildContext, Widget, LottieComposition?)? frameBuilder,
    Widget? errorWidget,
  }) {
    return LottieAnimation._(
      key: key,
      assetPath: assetPath,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      reverse: reverse,
      speed: speed,
      onLoaded: onLoaded,
      frameBuilder: frameBuilder,
      errorWidget: errorWidget,
    );
  }

  /// Create a Lottie animation from a network URL.
  factory LottieAnimation.network(
    String url, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool reverse = false,
    double? speed,
    void Function(LottieComposition)? onLoaded,
    Widget Function(BuildContext, Widget, LottieComposition?)? frameBuilder,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    return LottieAnimation._(
      key: key,
      networkUrl: url,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      reverse: reverse,
      speed: speed,
      onLoaded: onLoaded,
      frameBuilder: frameBuilder,
      errorWidget: errorWidget,
      loadingWidget: loadingWidget,
    );
  }

  /// Create a Lottie animation using a preset.
  factory LottieAnimation.preset(
    LottiePreset preset, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool? repeat,
    bool reverse = false,
    double? speed,
    void Function(LottieComposition)? onLoaded,
  }) {
    return LottieAnimation._(
      key: key,
      assetPath: preset.assetPath,
      width: width ?? preset.defaultSize,
      height: height ?? preset.defaultSize,
      fit: fit,
      repeat: repeat ?? preset.defaultRepeat,
      reverse: reverse,
      speed: speed,
      onLoaded: onLoaded,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (networkUrl != null) {
      return Lottie.network(
        networkUrl!,
        width: width,
        height: height,
        fit: fit,
        repeat: repeat,
        reverse: reverse,
        onLoaded: onLoaded,
        frameBuilder: frameBuilder,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildErrorWidget(context);
        },
      );
    }

    return Lottie.asset(
      assetPath!,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      reverse: reverse,
      onLoaded: onLoaded,
      frameBuilder: frameBuilder,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorWidget(context);
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return SizedBox(
      width: width ?? 100,
      height: height ?? 100,
      child: Icon(
        Icons.animation_outlined,
        size: 32,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

/// Predefined animation presets for common use cases in BayNavigator.
enum LottiePreset {
  loading(
    assetPath: 'assets/animations/loading.json',
    defaultSize: 80,
    defaultRepeat: true,
  ),
  success(
    assetPath: 'assets/animations/success.json',
    defaultSize: 100,
    defaultRepeat: false,
  ),
  error(
    assetPath: 'assets/animations/error.json',
    defaultSize: 100,
    defaultRepeat: false,
  ),
  emptyState(
    assetPath: 'assets/animations/empty_state.json',
    defaultSize: 150,
    defaultRepeat: true,
  ),
  welcome(
    assetPath: 'assets/animations/welcome.json',
    defaultSize: 200,
    defaultRepeat: true,
  ),
  confetti(
    assetPath: 'assets/animations/confetti.json',
    defaultSize: 300,
    defaultRepeat: false,
  ),
  mapPin(
    assetPath: 'assets/animations/map_pin.json',
    defaultSize: 60,
    defaultRepeat: true,
  ),
  search(
    assetPath: 'assets/animations/search.json',
    defaultSize: 80,
    defaultRepeat: true,
  ),
  heart(
    assetPath: 'assets/animations/heart.json',
    defaultSize: 50,
    defaultRepeat: false,
  ),
  checkmark(
    assetPath: 'assets/animations/checkmark.json',
    defaultSize: 60,
    defaultRepeat: false,
  );

  final String assetPath;
  final double defaultSize;
  final bool defaultRepeat;

  const LottiePreset({
    required this.assetPath,
    required this.defaultSize,
    required this.defaultRepeat,
  });
}

/// Extension for easier usage with animation controllers.
extension LottieControllerExtension on AnimationController {
  /// Convenience method to play a Lottie animation once.
  Future<void> playOnce() async {
    forward();
    await Future.delayed(duration ?? Duration.zero);
  }

  /// Convenience method to play and reverse a Lottie animation.
  Future<void> playAndReverse() async {
    await forward();
    await reverse();
  }
}
