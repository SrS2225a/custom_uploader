import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

final Dio dio = Dio()
  ..interceptors.add(
    DioCacheInterceptor(
      options: CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.forceCache,
        maxStale: const Duration(days: 7),
      ),
    ),
  );

final Map<String, Uint8List?> faviconCache = {};

Future<Uint8List?> getFavicon(String url) async {
  if (faviconCache.containsKey(url)) {
    return faviconCache[url]; // Return cached favicon if available
  }

  try {
    Response<List<int>> response = await dio.get(
      'https://www.google.com/s2/favicons?domain=$url&sz=256',
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode == 200 && response.data != null) {
      final favicon = Uint8List.fromList(response.data!);
      faviconCache[url] = favicon; // Cache the fetched favicon
      return favicon;
    }
  } catch (error) {
    print('Error fetching favicon: $error');
  }
  return null;
}

Widget buildFaviconImage(String uploaderUrl) {
  if (faviconCache.containsKey(uploaderUrl) && faviconCache[uploaderUrl] != null) {
    return Image.memory(faviconCache[uploaderUrl]!, width: 32, height: 32, fit: BoxFit.fill);
  } else {
    return FutureBuilder<Uint8List?>(
      future: getFavicon(uploaderUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 32, height: 32, child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Icon(Icons.public, size: 32);
        } else {
          return Image.memory(snapshot.data!, width: 32, height: 32, fit: BoxFit.fill);
        }
      },
    );
  }
}