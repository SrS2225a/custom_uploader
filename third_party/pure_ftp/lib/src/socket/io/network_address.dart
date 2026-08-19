import 'dart:io';

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
    final result = <NetworkAddressImpl>[];
    final addresses = await InternetAddress.lookup(host);
    for (final address in addresses) {
      final networkAddress = NetworkAddressImpl();
      networkAddress._address = address.address;
      networkAddress._host = address.host;
      result.add(networkAddress);
    }
    return result;
  }

  factory NetworkAddressImpl.anyIPv4() {
    final result = NetworkAddressImpl();
    final address = InternetAddress.anyIPv4;
    result._address = address.address;
    result._host = address.host;
    return result;
  }

  factory NetworkAddressImpl.anyIPv6() {
    final result = NetworkAddressImpl();
    final address = InternetAddress.anyIPv6;
    result._address = address.address;
    result._host = address.host;
    return result;
  }
}
