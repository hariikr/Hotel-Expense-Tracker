import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_theme.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onResult;
  final Color? color;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.color,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      // Request microphone permission
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Microphone permission is required for voice input'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.errorMsg}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              String text = result.recognizedWords;
              // Extract numbers from speech
              String numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
              if (numbers.isNotEmpty) {
                widget.onResult(numbers);
              }
              setState(() => _isListening = false);
            }
          },
          listenFor: const Duration(seconds: 5),
          pauseFor: const Duration(seconds: 3),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _listen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening
                  ? Colors.red
                      .withOpacity(0.5 + _animationController.value * 0.5)
                  : (widget.color ?? AppTheme.primaryColor),
              size: 24,
            );
          },
        ),
      ),
    );
  }
}
