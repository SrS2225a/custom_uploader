import 'package:pure_ftp/src/socket/html/network_address.dart'
    if (dart.library.io) 'package:pure_ftp/src/socket/io/network_address.dart';

abstract class WebIONetworkAddress {
  static Future<List<WebIONetworkAddress>> lookup(String host) async =>
      NetworkAddressImpl.lookup(host);

  String get address;

  String get host;

  static WebIONetworkAddress get anyIPv4 => NetworkAddressImpl.anyIPv4();

  static WebIONetworkAddress get anyIPv6 => NetworkAddressImpl.anyIPv6();
}
