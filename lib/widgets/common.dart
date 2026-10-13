import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Rounded surface used for every card in the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? p.surface) : null,
        gradient: gradient,
        borderRadius: r,
        border: Border.all(color: borderColor ?? p.line),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Consistent page title used on every tab.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const PageHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(color: p.muted, fontSize: 13)),
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const StatCard(this.label, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Expanded(
      child: AppCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: p.accent),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: p.muted)),
        ]),
      ),
    );
  }
}

/// Circular progress that animates smoothly between values.
class ProgressRing extends StatelessWidget {
  final double value, size, stroke;
  final Color? color;
  final Widget child;
  const ProgressRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 72,
    this.stroke = 7,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: value),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                color: color ?? p.accent,
                backgroundColor: p.surface2),
          ),
        ),
        child,
      ]),
    );
  }
}

/// Small rounded label ("Next · 23m", "Special day").
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
      );
}
