import 'package:flutter/material.dart';

class ColorPickerSheet extends StatefulWidget {
  const ColorPickerSheet({super.key, required this.initialColor});
  final Color initialColor;

  static Future<Color?> show(BuildContext context, Color initial) {
    return showModalBottomSheet<Color>(
      context: context,
      builder: (_) => ColorPickerSheet(initialColor: initial),
    );
  }

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  late double _hue, _saturation, _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _currentColor => HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Text('Hue'), Slider(value: _hue, min: 0, max: 360, onChanged: (v) => setState(() => _hue = v)),
            Text('Saturation'), Slider(value: _saturation, min: 0, max: 1, onChanged: (v) => setState(() => _saturation = v)),
            Text('Value'), Slider(value: _value, min: 0, max: 1, onChanged: (v) => setState(() => _value = v)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, _currentColor),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}