import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants.dart';

class PayslipViewScreen extends StatefulWidget {
  final String htmlBase64;
  final String title;

  const PayslipViewScreen({super.key, required this.htmlBase64, required this.title});

  @override
  State<PayslipViewScreen> createState() => _PayslipViewScreenState();
}

class _PayslipViewScreenState extends State<PayslipViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    String htmlContent;
    if (widget.htmlBase64.contains('base64,')) {
      htmlContent = utf8.decode(base64.decode(widget.htmlBase64.split('base64,')[1]));
    } else {
      htmlContent = widget.htmlBase64; // Fallback if it's already plain HTML
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
