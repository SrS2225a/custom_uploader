import 'package:pure_ftp/src/socket/common/web_io_network_address.dart';

class NetworkAddressImpl extends WebIONetworkAddress {
  late String _address;
  late String _host;

  NetworkAddressImpl();

  @override
  String get address => _address;

  @override
  String get host => _host;

  static Future<List<NetworkAddressImpl>> lookup(String host) async {
    throw UnimplementedError();
  }

  factory NetworkAddressImpl.anyIPv4() {
    throw UnimplementedError();
  }

  factory NetworkAddressImpl.anyIPv6() {
    throw UnimplementedError();
  }
}
