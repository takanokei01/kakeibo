import 'package:flutter/material.dart';

class NumPad extends StatefulWidget {
  final void Function(int amount) onSubmit;
  const NumPad({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _NumPadState createState() => _NumPadState();
}

class _NumPadState extends State<NumPad> {
  String _input = '';
  String _previousValue = '';
  String _operator = '';
  bool _shouldResetInput = false;

  void _append(String s) {
    setState(() {
      if (_shouldResetInput) {
        _input = s;
        _shouldResetInput = false;
      } else {
        if (_input == '0') _input = s;
        else _input = (_input + s).replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  void _setOperator(String op) {
    if (_input.isEmpty) return;
    _previousValue = _input;
    _operator = op;
    _shouldResetInput = true;
  }

  void _calculate() {
    if (_input.isEmpty || _previousValue.isEmpty || _operator.isEmpty) return;
    final prev = int.tryParse(_previousValue) ?? 0;
    final curr = int.tryParse(_input) ?? 0;
    int result = 0;

    switch (_operator) {
      case '+':
        result = prev + curr;
        break;
      case '−':
        result = prev - curr;
        break;
      case '×':
        result = prev * curr;
        break;
      case '÷':
        result = curr != 0 ? (prev ~/ curr) : 0;
        break;
    }

    setState(() {
      _input = result.toString();
      _previousValue = '';
      _operator = '';
      _shouldResetInput = true;
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
      _previousValue = '';
      _operator = '';
      _shouldResetInput = false;
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
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          onPressed: onTap ?? () => _append(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(label, style: const TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _opBtn(String label, void Function() onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(label, style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          alignment: Alignment.centerRight,
          child: Text(
            _input.isEmpty ? '0' : _input,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Row(children: [
          _btn('1'),
          _btn('2'),
          _btn('3'),
          _opBtn('+', () => _setOperator('+')),
        ]),
        Row(children: [
          _btn('4'),
          _btn('5'),
          _btn('6'),
          _opBtn('−', () => _setOperator('−')),
        ]),
        Row(children: [
          _btn('7'),
          _btn('8'),
          _btn('9'),
          _opBtn('×', () => _setOperator('×')),
        ]),
        Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ElevatedButton(
                onPressed: _clear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('C', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
          _btn('0'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ElevatedButton(
                onPressed: _backspace,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Icon(Icons.backspace, size: 20),
                ),
              ),
            ),
          ),
          _opBtn('÷', () => _setOperator('÷')),
        ]),
        Row(children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 59, 222, 41)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('追加', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('=', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          )
        ])
      ],
    );
  }
}
