import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../state/editor_controller.dart';
import '../state/editor_state.dart';

/// The bottom control surface of the editor: tool switcher and contextual
/// panels (colour palette, brush size, creature size). The Add button jumps
/// straight into the 3D pose booth.
class EditorToolbars extends StatelessWidget {
  const EditorToolbars({
    required this.state,
    required this.controller,
    required this.onAdd,
    required this.onAutoColor,
    required this.onSampleFromCanvas,
    super.key,
  });

  final EditorState state;
  final EditorController controller;
  final VoidCallback onAdd;
  final VoidCallback onAutoColor;
  final VoidCallback onSampleFromCanvas;

  @override
  Widget build(BuildContext context) {
    final hasSelection = state.selected != null;
    final l = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFF141222),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contextual panel above the tool row.
          if (state.tool == EditorTool.brush || state.tool == EditorTool.eraser)
            _BrushPanel(
              state: state,
              controller: controller,
              onAutoColor: onAutoColor,
              onSample: onSampleFromCanvas,
            ),
          const SizedBox(height: 10),
          // Creature size slider (move tool + selection).
          if (hasSelection &&
              state.tool == EditorTool.move &&
              !state.zoomEnabled)
            Row(
              children: [
                const Icon(
                  Icons.photo_size_select_small,
                  color: Colors.white70,
                  size: 18,
                ),
                Expanded(
                  child: Slider(
                    value: state.selected!.size.clamp(0.05, 0.9),
                    min: 0.05,
                    max: 0.9,
                    onChanged: (v) => controller.transformSelected(size: v),
                    onChangeEnd: (_) => controller.endTransform(),
                  ),
                ),
                const Icon(
                  Icons.photo_size_select_large,
                  color: Colors.white70,
                  size: 22,
                ),
              ],
            ),
          // Object actions (only when an Inkling is selected).
          if (hasSelection)
            Row(
              children: [
                _ActionChip(
                  icon: Icons.copy,
                  label: l.duplicate,
                  onTap: controller.duplicateSelected,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.delete_outline,
                  label: l.delete,
                  onTap: controller.deleteSelected,
                  danger: true,
                ),
              ],
            ),
          if (hasSelection) const SizedBox(height: 10),
          // Tool row.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(
                icon: Icons.open_with,
                label: l.toolMove,
                active: state.tool == EditorTool.move && !state.zoomEnabled,
                onTap: () => controller.setTool(EditorTool.move),
              ),
              _ToolButton(
                icon: Icons.brush,
                label: l.toolBrush,
                active: state.tool == EditorTool.brush && !state.zoomEnabled,
                enabled: hasSelection,
                onTap: () => controller.setTool(EditorTool.brush),
              ),
              _ToolButton(
                icon: Icons.colorize,
                label: l.toolPipette,
                active:
                    state.tool == EditorTool.eyedropper && !state.zoomEnabled,
                enabled: hasSelection,
                onTap: onSampleFromCanvas,
              ),
              _ToolButton(
                icon: Icons.auto_fix_high,
                label: l.toolErase,
                active: state.tool == EditorTool.eraser && !state.zoomEnabled,
                enabled: hasSelection,
                onTap: () => controller.setTool(EditorTool.eraser),
              ),
              _ToolButton(
                icon:
                    state.zoomEnabled ? Icons.zoom_in : Icons.zoom_in_outlined,
                label: l.toolZoom,
                active: state.zoomEnabled,
                onTap: controller.toggleZoom,
              ),
              _ToolButton(
                icon: Icons.add_reaction_outlined,
                label: l.toolAdd,
                active: false,
                onTap: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrushPanel extends StatelessWidget {
  const _BrushPanel({
    required this.state,
    required this.controller,
    required this.onAutoColor,
    required this.onSample,
  });

  final EditorState state;
  final EditorController controller;
  final VoidCallback onAutoColor;
  final VoidCallback onSample;

  static const _palette = [
    Color(0xFF2D3436),
    Color(0xFF636E72),
    Color(0xFFB2BEC3),
    Color(0xFFFFFFFF),
    Color(0xFFE17055),
    Color(0xFFFDCB6E),
    Color(0xFF00B894),
    Color(0xFF0984E3),
    Color(0xFF6C5CE7),
    Color(0xFFD63031),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _AutoColorButton(onTap: onAutoColor),
              const SizedBox(width: 8),
              for (final c in _palette) ...[
                _Swatch(
                  color: c,
                  selected: state.brushColor.value == c.value,
                  onTap: () => controller.setBrushColor(c),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Row(
          children: [
            const Icon(Icons.line_weight, color: Colors.white70, size: 18),
            Expanded(
              child: Slider(
                value: state.brushSize,
                min: 0.02,
                max: 0.30,
                onChanged: controller.setBrushSize,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: state.tool == EditorTool.eraser
                    ? Colors.white
                    : state.brushColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AutoColorButton extends StatelessWidget {
  const _AutoColorButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const SweepGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFDCB6E),
              Color(0xFF00B894),
              Color(0xFF0984E3),
              Color(0xFFFF6B6B),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.splash : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.white24
        : active
            ? AppColors.splash
            : Colors.white;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.splash.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.coral : Colors.white;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          minimumSize: const Size.fromHeight(40),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
