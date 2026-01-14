import 'package:flutter/material.dart';

class NumPad extends StatefulWidget {
  final void Function(int amount) onSubmit;
  const NumPad({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _NumPadState createState() => _NumPadState();
}

class _NumPadState extends State<NumPad> {
  String _input = '';

  void _append(String s) {
    setState(() {
      // avoid leading zeros
      if (_input == '0') _input = s;
      else _input = (_input + s).replaceFirst(RegExp(r'^0+'), '');
    });
  }

  void _backspace() {
    setState(() {
      if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
    });
  }

  void _clear() {
    setState(() {
      _input = '';
    });
  }

  void _submit() {
    if (_input.isEmpty) return;
    final value = int.tryParse(_input) ?? 0;
    if (value > 0) {
      widget.onSubmit(value);
      _clear();
    }
  }

  Widget _btn(String label, {VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: onTap ?? () => _append(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Text(label, style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          alignment: Alignment.centerRight,
          child: Text(
            _input.isEmpty ? '0' : _input,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        Row(children: [
          _btn('1'),
          _btn('2'),
          _btn('3'),
        ]),
        Row(children: [
          _btn('4'),
          _btn('5'),
          _btn('6'),
        ]),
        Row(children: [
          _btn('7'),
          _btn('8'),
          _btn('9'),
        ]),
        Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: _clear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('C', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ),
          _btn('0'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: _backspace,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Icon(Icons.backspace),
                ),
              ),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('追加', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        )
        ],
      ),
    );
  }
}
