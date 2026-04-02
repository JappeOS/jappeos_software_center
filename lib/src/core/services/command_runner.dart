class CommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration duration;

  bool get success => exitCode == 0;

  CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });
}

abstract class CommandRunner {
  Future<CommandResult> run(
    String executable,
    List<String> args, {
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? environment,
    String? workingDirectory,
  });
}