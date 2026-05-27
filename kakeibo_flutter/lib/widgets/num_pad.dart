import 'package:flutter/material.dart';

class NumPad extends StatefulWidget {
  final void Function(int amount) onSubmit;
  const NumPad({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _NumPadState createState() => _NumPadState();
}

class _NumPadState extends State<NumPad> {
  String _input = '';
  String _formula = '';
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
    setState(() {
      if (_input.isEmpty) {
        if (_formula.isEmpty) return;
        if (_formula.trim().endsWith('+') || _formula.trim().endsWith('−') || _formula.trim().endsWith('×') || _formula.trim().endsWith('÷')) {
          _formula = _formula.trim().substring(0, _formula.trim().length - 1).trimRight() + ' $op ';
        }
        _operator = op;
        return;
      }

      _formula = '$_formula${_input.trim()} $op ';
      _operator = op;
      _input = '';
      _shouldResetInput = false;
    });
  }

  void _calculate() {
    final expression = (_formula + _input).trim();
    if (expression.isEmpty) return;
    final tokens = expression.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return;

    int result = int.tryParse(tokens.first) ?? 0;
    for (var i = 1; i + 1 < tokens.length; i += 2) {
      final op = tokens[i];
      final next = int.tryParse(tokens[i + 1]) ?? 0;
      switch (op) {
        case '+':
          result += next;
          break;
        case '−':
          result -= next;
          break;
        case '×':
          result *= next;
          break;
        case '÷':
          result = next != 0 ? (result ~/ next) : result;
          break;
      }
    }

    setState(() {
      _input = result.toString();
      _formula = '';
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
      _formula = '';
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
    final bool isActive = _operator == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            side: isActive ? const BorderSide(width: 2.0, color: Colors.white) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _formulaText {
    if (_formula.isEmpty) return '';
    if (_input.isEmpty) return _formula.trimRight();
    return '$_formula$_input';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_formulaText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                _formulaText,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.right,
              ),
            ),
          ),
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
