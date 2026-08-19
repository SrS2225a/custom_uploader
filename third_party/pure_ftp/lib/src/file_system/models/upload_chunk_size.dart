enum UploadChunkSize {
  kb1(1024),
  kb2(2048),
  kb4(4096),
  mb1(1024 * 1024),
  mb2(2 * 1024 * 1024),
  mb4(4 * 1024 * 1024),
  ;

  final int value;

  const UploadChunkSize(this.value);

  @override
  String toString() => 'UploadChunkSize(${value}b)';
}
