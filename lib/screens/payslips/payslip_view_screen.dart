import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
  late final String _htmlContent;

  @override
  void initState() {
    super.initState();
    
    String rawHtml;
    if (widget.htmlBase64.contains('base64,')) {
      rawHtml = utf8.decode(base64.decode(widget.htmlBase64.split('base64,')[1]));
    } else {
      rawHtml = widget.htmlBase64; // Fallback if it's already plain HTML
    }

    // Inject CSS to hide buttons (specifically the internal print button)
    // Inject CSS and Meta tag to fit page and hide buttons
    _htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body { 
              padding-right: 10px; 
              font-family: sans-serif;
              width: 100%;
              margin: 0;
            }
            table { 
              width: 100% !important; 
              border-collapse: collapse; 
            }
            img { 
              max-width: 100% !important; 
              height: auto; 
            }
            button, .print-button, input[type="button"], input[type="submit"] {
              display: none !important;
            }
            @media print {
              @page { margin: 24px; }
              * { box-sizing: border-box; }
              body { 
                padding-right: 0 !important; 
                margin: 0 auto !important;
                width: 95% !important;
              }
              table { width: 100% !important; border-collapse: collapse; }
              button, .print-button, input[type="button"], input[type="submit"] {
                display: none !important;
              }
            }
          </style>
        </head>
        <body>
          $rawHtml
        </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_htmlContent);
  }

  Future<void> _printPayslip() async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await Printing.convertHtml(
        format: format,
        html: _htmlContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printPayslip,
              tooltip: 'Print Payslip',
            ),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
