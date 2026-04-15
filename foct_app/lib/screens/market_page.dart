import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  late final WebViewController controller;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
          },
          onPageFinished: (url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              isLoading = false;
              errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://artbiglobalph.com/atomy'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Market")),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),

          if (isLoading)
            const Center(child: CircularProgressIndicator()),

          if (errorMessage != null)
            Center(
              child: Text(
                "Error: $errorMessage",
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}