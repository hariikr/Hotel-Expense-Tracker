import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

class CalculatorDialog extends StatefulWidget {
  final String? initialValue;

  const CalculatorDialog({super.key, this.initialValue});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _expression = '';
  String _result = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _display = widget.initialValue!;
      _expression = widget.initialValue!;
    }
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _display = '0';
        _expression = '';
        _result = '';
      } else if (value == '=') {
        _calculateResult();
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _display = _expression.isEmpty ? '0' : _expression;
          _result = ''; // Clear result when editing
        }
      } else {
        // Handle operators
        if (['+', '-', '×', '÷'].contains(value)) {
          if (_expression.isNotEmpty &&
              !['+', '-', '×', '÷']
                  .contains(_expression[_expression.length - 1])) {
            _expression += value;
            _display = _expression;
            _result = ''; // Clear result when adding operator
          }
        } else {
          // Handle numbers
          if (_display == '0' || _display == 'Error') {
            _expression = value;
          } else {
            _expression += value;
          }
          _display = _expression;
          _result = ''; // Clear result when typing
        }
      }
    });
  }

  void _calculateResult() {
    try {
      String exp = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll(' ', '');

      if (exp.isEmpty) return;

      // Simple calculator using eval-like approach
      double calculatedResult = _evaluateExpression(exp);
      _result = calculatedResult.toStringAsFixed(
          calculatedResult.truncateToDouble() == calculatedResult ? 0 : 2);
      // Keep expression visible, show result separately
    } catch (e) {
      _result = 'Error';
    }
  }

  double _evaluateExpression(String exp) {
    // Simple expression evaluator for basic operations
    List<String> tokens = [];
    String currentNumber = '';

    for (int i = 0; i < exp.length; i++) {
      String char = exp[i];
      if ('0123456789.'.contains(char)) {
        currentNumber += char;
      } else if ('+-*/'.contains(char)) {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
        }
        tokens.add(char);
      }
    }
    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }

    // First handle * and /
    for (int i = 1; i < tokens.length - 1; i += 2) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        double left = double.parse(tokens[i - 1]);
        double right = double.parse(tokens[i + 1]);
        double result = tokens[i] == '*' ? left * right : left / right;
        tokens[i - 1] = result.toString();
        tokens.removeAt(i);
        tokens.removeAt(i);
        i -= 2;
      }
    }

    // Then handle + and -
    double result = double.parse(tokens[0]);
    for (int i = 1; i < tokens.length - 1; i += 2) {
      double right = double.parse(tokens[i + 1]);
      if (tokens[i] == '+') {
        result += right;
      } else if (tokens[i] == '-') {
        result -= right;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calculator',
                  style: AppTheme.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Display Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expression display
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _display.isEmpty ? '0' : _display,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 18,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  // Result display
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _result.isEmpty ? '' : '= $_result',
                      style: AppTheme.headingLarge.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              childAspectRatio: 1.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildButton('7'),
                _buildButton('8'),
                _buildButton('9'),
                _buildButton('÷', color: AppTheme.primaryColor),
                _buildButton('4'),
                _buildButton('5'),
                _buildButton('6'),
                _buildButton('×', color: AppTheme.primaryColor),
                _buildButton('1'),
                _buildButton('2'),
                _buildButton('3'),
                _buildButton('-', color: AppTheme.primaryColor),
                _buildButton('C', color: Colors.red),
                _buildButton('0'),
                _buildButton('=', color: AppTheme.profitColor),
                _buildButton('+', color: AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final valueToCopy =
                          _result.isNotEmpty ? _result : _display;
                      if (valueToCopy != 'Error' &&
                          valueToCopy != '0' &&
                          valueToCopy.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: valueToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied: $valueToCopy'),
                            backgroundColor: AppTheme.profitColor,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_expression.isNotEmpty) {
                          _expression =
                              _expression.substring(0, _expression.length - 1);
                          _display = _expression.isEmpty ? '0' : _expression;
                          _result = '';
                        }
                      });
                    },
                    icon: const Icon(Icons.backspace, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final valueToUse =
                          _result.isNotEmpty ? _result : _display;
                      if (valueToUse != 'Error' &&
                          valueToUse != '0' &&
                          valueToUse.isNotEmpty) {
                        Navigator.pop(context, valueToUse);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.profitColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Use This Value'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String value, {Color? color}) {
    return Material(
      color: color?.withOpacity(0.1) ?? Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _onButtonPressed(value),
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget to show calculator button
class CalculatorButton extends StatelessWidget {
  final TextEditingController controller;
  final Color? color;

  const CalculatorButton({
    super.key,
    required this.controller,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.calculate_outlined,
        color: color ?? AppTheme.primaryColor,
      ),
      onPressed: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => CalculatorDialog(
            initialValue: controller.text,
          ),
        );
        if (result != null) {
          controller.text = result;
        }
      },
    );
  }
}
