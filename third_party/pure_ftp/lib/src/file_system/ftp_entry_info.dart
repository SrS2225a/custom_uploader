class FtpEntryInfo {
  final String name;
  final String? modifyTime;
  final String? permissions;
  final int? size;
  final String? unique;
  final String? group;
  final int gid;
  final String? mode;
  final String? owner;
  final int uid;
  final Map<String, String> additional;

  FtpEntryInfo({
    required this.name,
    this.modifyTime,
    this.permissions,
    this.size,
    this.unique,
    this.group,
    this.gid = -1,
    this.mode,
    this.owner,
    this.uid = -1,
    this.additional = const {},
  });

  @override
  String toString() {
    return 'FtpEntryInfo(name: $name, modifyTime: $modifyTime, permissions: $permissions, size: $size, unique: $unique, group: $group, gid: $gid, mode: $mode, owner: $owner, uid: $uid, additional: $additional)';
  }
}
