import 'package:flutter/material.dart';

class GlossaryFilterOption {
  final String value;
  final String label;

  const GlossaryFilterOption(this.value, this.label);
}

class GlossaryFilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<GlossaryFilterOption> options;
  final ValueChanged<String?> onChanged;

  const GlossaryFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
