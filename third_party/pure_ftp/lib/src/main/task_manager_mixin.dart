import 'dart:async';

import 'package:pure_ftp/src/ftp/ftp_task.dart';

mixin TaskManagerMixin {
  final _tasks = <FtpTask>[];

  void addTask(FtpTask task) {
    _tasks.add(task);
  }

  /// run all tasks in queue, if any task fails, then next tasks will not be executed
  /// and exception of failed task will be thrown
  Future<void> runTasks() async {
    if (_tasks.isEmpty) {
      return;
    }
    var completedTasks = 0;
    late FtpTask task;
    while (completedTasks < _tasks.length) {
      task = _tasks[completedTasks];
      await task.run();
      if (!task.isSuccessful) {
        break;
      }
      completedTasks++;
    }
    _tasks.removeRange(0, completedTasks);
    try {
      task.result;
    } finally {
      await task.reset();
    }
  }

  Future<void> runTasksUnsafe() async {
    if (_tasks.isEmpty) {
      return;
    }
    var completedTasks = 0;
    late FtpTask task;
    while (completedTasks < _tasks.length) {
      task = _tasks[completedTasks];
      await task.run();
      completedTasks++;
    }
    _tasks.removeRange(0, completedTasks);
    task.result;
  }

  Future<T> runAsTask<T>(FutureOr<T> Function() task) {
    final ftpTask = FtpTask<T>(task: task);
    return runTask(ftpTask);
  }

  Future<T> runTask<T>(FtpTask<T> task) async {
    await runTasks();
    return task.result;
  }

  Future<void> cancelTasks() async {
    for (final task in _tasks) {
      await task.cancel();
    }
    _tasks.clear();
  }

  void resetTasks() {
    for (final task in _tasks) {
      task.reset();
    }
  }

  void clearTasks() {
    _tasks.clear();
  }
}
