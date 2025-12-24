/// A single parsed stack frame for structured stack trace display.
/// 
/// Matches the format sent by the telling_logger SDK's `stackTraceElements`.
class StackTraceFrame {
  final String file;
  final int line;
  final int? column;
  final String method;
  final String? className;

  const StackTraceFrame({
    required this.file,
    required this.line,
    this.column,
    required this.method,
    this.className,
  });

  factory StackTraceFrame.fromJson(Map<String, dynamic> json) {
    return StackTraceFrame(
      file: json['file'] as String? ?? '',
      line: int.tryParse(json['line']?.toString() ?? '0') ?? 0,
      column: json['column'] != null
          ? int.tryParse(json['column'].toString())
          : null,
      method: json['method'] as String? ?? '<unknown>',
      className: json['class'] as String?,
    );
  }

  /// Display name combining class and method
  String get displayName {
    if (className != null && className!.isNotEmpty) {
      return '$className.$method';
    }
    return method;
  }

  /// Short file name (just the basename)
  String get shortFile {
    final parts = file.split('/');
    return parts.isNotEmpty ? parts.last : file;
  }
}
