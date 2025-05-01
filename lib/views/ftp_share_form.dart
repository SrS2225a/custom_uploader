import 'package:flutter/material.dart';
import 'package:custom_uploader/services/database.dart';
import 'package:hive/hive.dart';
import 'package:pure_ftp/pure_ftp.dart';

import '../utils/show_message.dart';

class FTPShareForm extends StatefulWidget {
  final NetworkShare? editor;

  const FTPShareForm({super.key,  this.editor});

  @override
  State<FTPShareForm> createState() => _FTPShareFormState();
}

class _FTPShareFormState extends State<FTPShareForm> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _folderPathController = TextEditingController();
  final _portController = TextEditingController();
  final _urlPathController = TextEditingController();

  String _selectedProtocol = 'ftp://';

  @override
  void initState() {
    super.initState();

    if (widget.editor != null) {
      _domainController.text = widget.editor!.domain;
      _usernameController.text = widget.editor!.username;
      _passwordController.text = widget.editor!.password;
      _folderPathController.text = widget.editor!.folderPath;
      _portController.text = widget.editor!.port.toString();
      // _urlPathController.text = widget.editor!.urlPath.toString();

      // Extract protocol from urlPath if available
      if (widget.editor!.urlPath!.startsWith('https://')) {
        _selectedProtocol = 'https://';
        _urlPathController.text = widget.editor!.urlPath!.replaceFirst('https://', '').replaceAll(RegExp(r'^/+|/+$'), '').toString();
      } else if (widget.editor!.urlPath!.startsWith('http://')) {
        _selectedProtocol = 'http://';
        _urlPathController.text = widget.editor!.urlPath!.replaceFirst('http://', '').replaceAll(RegExp(r'^/+|/+$'), '');
      } else if (widget.editor!.urlPath!.startsWith('ftps://')) {
        _selectedProtocol = 'ftps://';
        _urlPathController.text = widget.editor!.urlPath!.replaceFirst('ftps://', '').replaceAll(RegExp(r'^/+|/+$'), '');
      } else {
        _selectedProtocol = 'ftp://';
        _urlPathController.text = widget.editor!.urlPath!.replaceFirst('ftp://', '').replaceAll(RegExp(r'^/+|/+$'), '');
      }
  } else {
      _folderPathController.text = "/";
      _portController.text = "21";
    }
}

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> testFtpConnection(NetworkShare share) async {
    final socketInitOptions = FtpSocketInitOptions(host: share.domain, port: share.port);
    final authOptions = FtpAuthOptions(username: share.username, password: share.password);

    try {
      final ftpClient = FtpClient(
          socketInitOptions: socketInitOptions, authOptions: authOptions);
      await ftpClient.connect();
      final isConnected = ftpClient.isConnected();
      await ftpClient.disconnect();
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  void _saveShare() async {
    final box = await Hive.openBox<NetworkShare>('share_upload');

    String fullUrl = _selectedProtocol + _urlPathController.text.trim();
    if(!fullUrl.endsWith("/")) {
      fullUrl += "/";
    }

    final newShare = NetworkShare(
      protocol: "ftp",
      domain: _domainController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      folderPath: _folderPathController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 0,
      urlPath: fullUrl,
    );

    if(widget.editor != null) {
      final index = box.values.toList().indexOf(widget.editor!);
      if(index != -1) {
        box.putAt(index, newShare);
      }
    } else {
      if(box.values.where((element) => element.domain == widget.editor!.domain).isEmpty) {
        box.add(newShare);
      } else {
        showSnackBar(context, "A share with that url already exists");
      }
    }

    if(mounted) Navigator.pop(context, newShare);
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if(required && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          } else {
            return null;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shareLabel = "FTP";

    return Scaffold(
      appBar: AppBar(
        title: Text('$shareLabel Uploader'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField(_domainController, '$shareLabel Domain (e.g., ftp.example.com)'),
            _buildField(_usernameController, 'Username', required: false),
            _buildField(_passwordController, 'Password', obscureText: true, required: false),
            _buildField(_portController, 'Port', keyboardType: TextInputType.number),
            _buildField(_folderPathController, 'Remote Folder Path'),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedProtocol,
                    decoration: const InputDecoration(
                      labelText: 'Protocol',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12,horizontal: 8),
                    ),
                    items: ['http://', 'https://', 'ftp://', 'ftps://']
                      .map((protocol) => DropdownMenuItem(
                        value: protocol,
                        child: Text(protocol),
                    )).toList(),
                    onChanged: (String? value) {
                      if(value != null) {
                       setState(() {
                         _selectedProtocol = value;
                       });
                      }
                    },
                  )
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _urlPathController,
                    decoration: InputDecoration(
                      labelText: 'URL Path',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12,horizontal: 8),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter URL Path' : null,
                  ),
                )
              ]
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _saveShare();
                          }
                        },
                        child: const Text('Save'),
                      ),
                    )
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    )
                ),
                // add test button
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: FilledButton(
                        onPressed: () async {
                          final testResult = await testFtpConnection(NetworkShare(
                              protocol: "ftp",
                              domain: _domainController.text.trim(),
                              username: _usernameController.text.trim(),
                              password: _passwordController.text.trim(),
                              folderPath: _folderPathController.text.trim(),
                              port: int.tryParse(_portController.text.trim()) ?? 0,
                              urlPath: _urlPathController.text.trim(),
                          ));
                          showSnackBar(context, testResult ? "Connection successful" : "Connection failed");
                        },
                        child: const Text('Test'),
                      )
                    )
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}