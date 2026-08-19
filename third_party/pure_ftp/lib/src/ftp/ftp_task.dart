import 'dart:async';

/// Task for FTPTaskManager
class FtpTask<T> {
  final FutureOr<T> Function() _task;
  TaskStatus _status;
  late T _result;
  late Object _error;
  late StackTrace _stackTrace;

  FtpTask({
    required FutureOr<T> Function() task,
  })  : _task = task,
        _status = TaskStatus.pending;

  /// true if the task have any result
  bool get isCompleted =>
      _status == TaskStatus.completed ||
      _status == TaskStatus.failed ||
      _status == TaskStatus.canceled;

  /// true if the task is completed successfully or canceled
  bool get isSuccessful =>
      _status == TaskStatus.completed || _status == TaskStatus.canceled;

  Future<void> run({int retryCount = 1}) async {
    if (_status == TaskStatus.pending) {
      _status = TaskStatus.running;
      try {
        int retry = 0;
        await Future.doWhile(() async {
          try {
            _result = await _task();
            return false;
          } catch (e, s) {
            _error = e;
            _stackTrace = s;
            if (retry++ >= retryCount) {
              return true;
            }
          }
          return true;
        });
        _result = await _task();
      } catch (e, s) {
        _status = TaskStatus.failed;
        _error = e;
        _stackTrace = s;
      }
      _status = TaskStatus.completed;
    }
  }

  Future<T> runAndGet() => run().then((value) => result);

  Future<void> cancel() async {
    if (_status == TaskStatus.pending) {
      _status = TaskStatus.canceled;
      return;
    }
  }

  Future<void> reset() async {
    if (isCompleted) {
      _status = TaskStatus.pending;
      return;
    } else {
      throw StateError('Task is not completed');
    }
  }

  T get result {
    if (_status == TaskStatus.completed) {
      return _result;
    } else {
      if (_status == TaskStatus.failed) {
        throw _error;
      }
    }
    throw StateError('Task is not completed');
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('FtpTask{status: $_status,');
    switch (_status) {
      case TaskStatus.completed:
        sb.write(' result: $_result');
        break;
      case TaskStatus.failed:
        sb.write(' error: $_error, stackTrace: \n$_stackTrace\n');
        break;
      default:
        break;
    }
    sb.write('}');
    return sb.toString();
  }
}

enum TaskStatus {
  pending,
  running,
  completed,
  failed,
  canceled,
}
