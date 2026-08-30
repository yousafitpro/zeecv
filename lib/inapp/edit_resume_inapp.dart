import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zeecv/core/utils/permission_helper.dart';
import 'package:zeecv/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart'; 
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
class EditResumeInapp extends StatefulWidget {
  const EditResumeInapp({Key? key}) : super(key: key);

  @override
  _EditResumeInappState createState() => _EditResumeInappState();
}

class _EditResumeInappState extends State<EditResumeInapp> {
  bool _showInAppBrowser = false;
  String? _inAppBrowserUrl;
  String? _downloadUrl;
  String? _previewUrl;
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      final token = user?.loginToken;
      if (token != null && token.isNotEmpty) {
        setState(() {
          _showInAppBrowser = true;
          _inAppBrowserUrl = 'https://zeecv.com/mobile-app/login-using-token/$token';
          _downloadUrl = 'https://zeecv.com/mobile-app/resume/download-pdf/$token';
          _previewUrl = 'https://zeecv.com/mobile-app/resume/preview/$token';
        });
      } else {
        print('User not logged in or token is missing');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to edit your resume'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _closeInAppBrowser() {
    setState(() {
      _showInAppBrowser = false;
      _inAppBrowserUrl = '';
      _webViewController = null;
      _progress = 0;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

Future<void> _handleDownload() async {
  // Remove this line (No permissions needed on Android 16)
  // final allowed = await PermissionHelper.requestStoragePermission();

  if (_downloadUrl == null || _downloadUrl!.isEmpty) {
    _showError('Download URL not available');
    return;
  }

  if (_isDownloading) {
    _showError('Download already in progress');
    return;
  }

  setState(() => _isDownloading = true);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Downloading resume...'),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 2),
    ),
  );

  try {
    // Get filename
    String filename = 'resume.pdf';

    try {
      final uri = Uri.parse(_downloadUrl!);
      final segments = uri.path.split('/');
      final lastSegment = segments.last;

      if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
        filename = Uri.decodeComponent(lastSegment);
      }
    } catch (_) {}

    // Download file
    final client = http.Client();

    try {
      final response = await client.get(Uri.parse(_downloadUrl!));

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }

      // Prevent overwriting existing files by adding a timestamp
      // (Since MediaStore doesn't easily check for existing files)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFilename = filename.replaceAll('.pdf', '_$timestamp.pdf');

      // 1. Save the file to the app's temporary directory FIRST
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$finalFilename');
      await tempFile.writeAsBytes(response.bodyBytes, flush: true);

      // 2. Use FlutterFileDialog to move it to the public Downloads folder via MediaStore
      final params = SaveFileDialogParams(
        sourceFilePath: tempFile.path,
        fileName: finalFilename,
      );
      
      final savedPath = await FlutterFileDialog.saveFile(params: params);

      if (savedPath != null) {
        final sizeInMB = (response.bodyBytes.length / (1024 * 1024)).toStringAsFixed(2);
        _showSuccess('Resume downloaded: $finalFilename ($sizeInMB MB)');
        _showDownloadCompleteDialog(savedPath); // Pass the path string instead of File
      } else {
        _showError('Download cancelled');
      }

      // Clean up temp file (optional but good practice)
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

    } finally {
      client.close();
    }
  } catch (e) {
    _showError('Download failed: $e');
    print('Download error: $e');
  } finally {
    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }
}
  Future<String> _getUniqueFilename(String directory, String baseFilename) async {
    final file = File('$directory/$baseFilename');
    if (!await file.exists()) {
      return baseFilename;
    }
    
    final lastDotIndex = baseFilename.lastIndexOf('.');
    final name = lastDotIndex > 0 ? baseFilename.substring(0, lastDotIndex) : baseFilename;
    final ext = lastDotIndex > 0 ? baseFilename.substring(lastDotIndex) : '';
    
    int counter = 1;
    while (true) {
      final newName = '$name ($counter)$ext';
      final newFile = File('$directory/$newName');
      if (!await newFile.exists()) {
        return newName;
      }
      counter++;
    }
  }

  // Change the parameter from File to String
  void _showDownloadCompleteDialog(String savedPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Complete'),
          content: Text(
            'Resume saved successfully!\n\nLocation: $savedPath',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  // --- END OF NEW DOWNLOAD HANDLING METHODS ---

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final backUrl = extra?['back_url'] as String? ?? '/home/find-jobs';

    if (_showInAppBrowser && _inAppBrowserUrl != null && _inAppBrowserUrl!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Edit Resume"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.go(backUrl);
            },
          ),
          actions: [
          
            IconButton(
              icon: _isDownloading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Icon(Icons.download),
              onPressed: _isDownloading ? null : _handleDownload, // ← CHANGED THIS
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (_webViewController != null) {
                  _webViewController?.reload();
                } else {
                  final authProvider = context.read<AuthProvider>();
                  final token = authProvider.user?.loginToken;
                  if (token != null && token.isNotEmpty) {
                    setState(() {
                      _showInAppBrowser = true;
                      _inAppBrowserUrl = 'https://zeecv.com/mobile-app/login-using-token/$token';
                    });
                  }
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
              key: ValueKey(_inAppBrowserUrl),
              initialUrlRequest: URLRequest(
                url: WebUri(_inAppBrowserUrl!),
              ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                  });
                },
                onLoadError: (controller, url, code, message) {
                  _showError('Failed to load page: $message');
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  _showError('HTTP Error $statusCode: $description');
                },
                // Add this to handle downloads from within WebView
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';
                  // If URL contains download-pdf, handle it as download
                  if (url.contains('download-pdf')) {
                    _handleDownload();
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_progress < 1.0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          child: const Text(''),
        ),
      ),
    );
  }
}