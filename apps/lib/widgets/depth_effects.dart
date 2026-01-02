import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that adds depth and 3D-like effects to its child
class DepthCard extends StatefulWidget {
  final Widget child;
  final double depth;
  final double hoverLift;
  final double hoverScale;
  final BorderRadius? borderRadius;
  final Color? shadowColor;
  final bool enabled;

  const DepthCard({
    super.key,
    required this.child,
    this.depth = 8,
    this.hoverLift = 8,
    this.hoverScale = 1.02,
    this.borderRadius,
    this.shadowColor,
    this.enabled = true,
  });

  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _liftAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _liftAnimation = Tween<double>(begin: 0, end: widget.hoverLift).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.hoverScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..setTranslationRaw(0.0, -_liftAnimation.value, 0.0)
              ..scaleByDouble(_scaleAnimation.value, _scaleAnimation.value, 1.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                boxShadow: [
                  // Ambient shadow (soft, spread out)
                  BoxShadow(
                    color: (widget.shadowColor ?? Colors.black).withValues(alpha: 0.08),
                    blurRadius: widget.depth + (_isHovered ? 20 : 0),
                    spreadRadius: _isHovered ? 2 : 0,
                    offset: Offset(0, widget.depth / 2),
                  ),
                  // Key shadow (sharper, directional)
                  BoxShadow(
                    color: (widget.shadowColor ?? Colors.black).withValues(alpha: 0.12),
                    blurRadius: widget.depth * 2 + (_isHovered ? 16 : 0),
                    offset: Offset(0, widget.depth + _liftAnimation.value),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// A floating action button with depth
class DepthFloatingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double size;

  const DepthFloatingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.size = 56,
  });

  @override
  State<DepthFloatingButton> createState() => _DepthFloatingButtonState();
}

class _DepthFloatingButtonState extends State<DepthFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // ignore: unused_field
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pressProgress = _controller.value;
          return Transform.translate(
            offset: Offset(0, pressProgress * 4),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 12 - (pressProgress * 8),
                    offset: Offset(0, 6 - (pressProgress * 4)),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20 - (pressProgress * 12),
                    offset: Offset(0, 10 - (pressProgress * 6)),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}

/// A panel that appears to float above the content
class FloatingPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double depth;
  final BorderRadius? borderRadius;

  const FloatingPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.depth = 12,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
          width: 1,
        ),
        boxShadow: [
          // Soft ambient shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: depth * 2,
            spreadRadius: 0,
            offset: Offset(0, depth / 3),
          ),
          // Sharper drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: depth,
            offset: Offset(0, depth / 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// A layered background that creates parallax depth
class ParallaxLayer extends StatefulWidget {
  final Widget child;
  final double parallaxFactor;
  final Alignment alignment;

  const ParallaxLayer({
    super.key,
    required this.child,
    this.parallaxFactor = 0.1,
    this.alignment = Alignment.center,
  });

  @override
  State<ParallaxLayer> createState() => _ParallaxLayerState();
}

class _ParallaxLayerState extends State<ParallaxLayer> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _offset = Offset(
            (event.position.dx - size.width / 2) * widget.parallaxFactor,
            (event.position.dy - size.height / 2) * widget.parallaxFactor,
          );
        });
      },
      onExit: (_) {
        setState(() => _offset = Offset.zero);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
        child: widget.child,
      ),
    );
  }
}

/// A glassmorphism-style container
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? tint;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 10,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: (tint ?? (isDark ? Colors.white : Colors.black)).withValues(alpha: isDark ? 0.1 : 0.05),
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// A widget that fades and slides in when it enters the viewport
/// Great for list items that should animate as they scroll into view
class ScrollFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double slideOffset;
  final Curve curve;
  final int index;

  const ScrollFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = 30,
    this.curve = Curves.easeOutCubic,
    this.index = 0,
  });

  @override
  State<ScrollFadeIn> createState() => _ScrollFadeInState();
}

class _ScrollFadeInState extends State<ScrollFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Stagger the animation based on index
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A widget that animates visibility based on scroll position
/// Fades out when scrolling out of view
class ScrollVisibilityFade extends StatefulWidget {
  final Widget child;
  final double fadeStartDistance;
  final double fadeEndDistance;

  const ScrollVisibilityFade({
    super.key,
    required this.child,
    this.fadeStartDistance = 50,
    this.fadeEndDistance = 150,
  });

  @override
  State<ScrollVisibilityFade> createState() => _ScrollVisibilityFadeState();
}

class _ScrollVisibilityFadeState extends State<ScrollVisibilityFade> {
  double _opacity = 1.0;
  double _translateY = 0.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _updateVisibility(context);
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Check visibility on first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateVisibility(context);
          });

          return AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(0, _translateY, 0),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  void _updateVisibility(BuildContext context) {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);

    final revealedOffset = viewport.getOffsetToReveal(renderObject, 0.0);
    final viewportHeight = viewport.paintBounds.height;
    final itemTop = revealedOffset.offset;
    final itemBottom = itemTop + renderObject.paintBounds.height;

    double newOpacity = 1.0;
    double newTranslateY = 0.0;

    // Fade out at top
    if (itemTop < widget.fadeStartDistance) {
      final progress = (widget.fadeStartDistance - itemTop) /
          (widget.fadeEndDistance - widget.fadeStartDistance);
      newOpacity = (1.0 - progress).clamp(0.0, 1.0);
      newTranslateY = progress * 10;
    }

    // Fade out at bottom
    if (itemBottom > viewportHeight - widget.fadeStartDistance) {
      final progress = (itemBottom - (viewportHeight - widget.fadeStartDistance)) /
          (widget.fadeEndDistance - widget.fadeStartDistance);
      newOpacity = (1.0 - progress).clamp(0.0, 1.0);
      newTranslateY = -progress * 10;
    }

    if (mounted && (newOpacity != _opacity || newTranslateY != _translateY)) {
      setState(() {
        _opacity = newOpacity;
        _translateY = newTranslateY;
      });
    }
  }
}

/// Adds a subtle 3D tilt effect based on pointer position
class TiltEffect extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final bool enabled;

  const TiltEffect({
    super.key,
    required this.child,
    this.maxTilt = 0.05,
    this.enabled = true,
  });

  @override
  State<TiltEffect> createState() => _TiltEffectState();
}

class _TiltEffectState extends State<TiltEffect> {
  double _rotateX = 0;
  double _rotateY = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onHover: (event) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final size = box.size;
        final localPosition = box.globalToLocal(event.position);

        setState(() {
          _rotateY = ((localPosition.dx / size.width) - 0.5) * widget.maxTilt;
          _rotateX = -((localPosition.dy / size.height) - 0.5) * widget.maxTilt;
        });
      },
      onExit: (_) {
        setState(() {
          _rotateX = 0;
          _rotateY = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotateX)
          ..rotateY(_rotateY),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
