import 'package:flutter/material.dart';

// Drop-in replacement for a TextFormField(obscureText: true) with a show/hide eye toggle —
// mirrors the web app's components/ui/PasswordInput.tsx (same reasoning: without this,
// there's no way to check a typo'd password before submitting). Local widget-owned
// visibility state, not autofillHints (password fields in this app deliberately opt out of
// autofill — see account_screen.dart's comment on why).
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.autofillHints,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          tooltip: _obscure ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
    );
  }
}
