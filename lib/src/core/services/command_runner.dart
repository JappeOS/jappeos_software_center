//  jappeos_software_center, A GUI app for installing software for JappeOS.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
    Duration? timeout = const Duration(seconds: 15),
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
    Duration? timeout = const Duration(seconds: 15),
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
      ).timeout(timeout ?? Duration(days: 1000));

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
        timeout: timeout ?? Duration(days: 1000),
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
