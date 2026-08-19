## 0.1.0

- Initial release

## 0.1.1

- Fix documentation and add test

## 0.3.0

- add capability to build on web(by adding abstract classes)
- now you can use this package on web and mobile but on web all the methods will throw an UnsupportedError
- Implements base of ftp file system
- add flutter web example[WIP]

## 0.4.1

- implements parse directory content on list command

## 0.4.2

- fix tests

## 0.5.0

- implements upload files to ftp server
- implements download files from ftp server
- implements create empty file on ftp server
- fix compat with web

## 0.5.1

- update example
- add function to get size of file

## 0.5.2

- fix timeout error on Windows

## 0.6.0

- adds download/upload callbacks
- export all references to lib file, use import 'package:pure_ftp/pure_ftp.dart'; now
- fix some bugs

## 0.7.0

- remake file system, now ftp entries has info in class and copyWith methods is changed.
- client's isConnected now sends request to server to check connection status

## 0.7.1

- fix restSize error on download

## 0.7.2

- fix error on list dir

## 0.7.3

- add flush method to socket
- fix download problem for any ftp servers

## 0.7.4

- fix get file error when unrecognized format

## 0.7.5

- speed up read ftp server response
- fix flushing "ok" server response after data transferring