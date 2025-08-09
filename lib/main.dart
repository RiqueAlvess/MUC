import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const UniquetrackApp());
}

class UniquetrackApp extends StatelessWidget {
  const UniquetrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uniquetrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const WebContainer(),
    );
  }
}

class WebContainer extends StatefulWidget {
  const WebContainer({super.key});
  @override
  State<WebContainer> createState() => _WebContainerState();
}

class _WebContainerState extends State<WebContainer> {
  late final WebViewController _controller;
  int _progress = 0;

  static const String initialUrl = 'https://uniquetrack.onrender.com/admin/';

  @override
  void initState() {
    super.initState();
    final params = const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onNavigationRequest: (request) async {
            final uri = Uri.parse(request.url);

            if (uri.scheme == 'tel' || uri.scheme == 'mailto') {
              await launchUrl(uri);
              return NavigationDecision.prevent;
            }

            final inApp = uri.host.contains('uniquetrack.onrender.com');
            if (!inApp) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));

    if (Platform.isAndroid) {
      WebView.platform = AndroidWebView();
    }
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_progress < 100)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(value: _progress / 100),
              ),
          ],
        ),
      ),
    );
  }
}
