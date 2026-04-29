import 'dart:async';
import 'dart:io';

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

class CommandTimeoutException implements Exception {
  final String executable;
  final List<String> args;
  final Duration timeout;

  CommandTimeoutException({
    required this.executable,
    required this.args,
    required this.timeout,
  });

  @override
  String toString() {
    final argString = args.join(' ');
    return 'Command timed out after ${timeout.inSeconds}s: $executable $argString';
  }
}

class CommandStartException implements Exception {
  final String executable;
  final List<String> args;
  final String message;

  CommandStartException({
    required this.executable,
    required this.args,
    required this.message,
  });

  @override
  String toString() {
    final argString = args.join(' ');
    return 'Failed to start command "$executable $argString": $message';
  }
}

class ProcessCommandRunner implements CommandRunner {
  const ProcessCommandRunner();

  @override
  Future<CommandResult> run(
    String executable,
    List<String> args, {
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? environment,
    String? workingDirectory,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final processResult = await Process.run(
        executable,
        args,
        runInShell: false,
        environment: environment,
        workingDirectory: workingDirectory,
      ).timeout(timeout);

      stopwatch.stop();

      return CommandResult(
        exitCode: processResult.exitCode,
        stdout: processResult.stdout.toString().trimRight(),
        stderr: processResult.stderr.toString().trimRight(),
        duration: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      throw CommandTimeoutException(
        executable: executable,
        args: args,
        timeout: timeout,
      );
    } on ProcessException catch (error) {
      stopwatch.stop();
      throw CommandStartException(
        executable: executable,
        args: args,
        message: error.message,
      );
    }
  }
}
