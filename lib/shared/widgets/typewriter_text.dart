import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration deletingSpeed;
  final Duration pauseDuration;

  const TypewriterText({
    super.key,
    required this.texts,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 100),
    this.deletingSpeed = const Duration(milliseconds: 50),
    this.pauseDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _currentText = '';
  int _currentIndex = 0;
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer?.cancel();
    
    if (_currentIndex >= widget.texts.length) {
      _currentIndex = 0;
    }

    final currentFullText = widget.texts[_currentIndex];

    if (_isDeleting) {
      _timer = Timer(widget.deletingSpeed, () {
        if (_charIndex > 0) {
          setState(() {
            _charIndex--;
            _currentText = currentFullText.substring(0, _charIndex);
          });
          _startTyping();
        } else {
          _isDeleting = false;
          _currentIndex++;
          _startTyping();
        }
      });
    } else {
      _timer = Timer(widget.typingSpeed, () {
        if (_charIndex < currentFullText.length) {
          setState(() {
            _charIndex++;
            _currentText = currentFullText.substring(0, _charIndex);
          });
          _startTyping();
        } else {
          _timer = Timer(widget.pauseDuration, () {
            _isDeleting = true;
            _startTyping();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_currentText|',
      style: widget.style,
    );
  }
}
