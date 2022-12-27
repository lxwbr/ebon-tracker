import 'package:ebon_tracker/application/database_service.dart';
import 'package:ebon_tracker/data/attachment.dart';
import 'package:ebon_tracker/data/category.dart';
import 'package:ebon_tracker/widgets/receipt.dart';
import 'package:flutter/material.dart';
import 'package:pdf_render/pdf_render_widgets.dart';

import '../data/receipt.dart';
import 'errors.dart';

class AttachmentPage extends StatelessWidget {
  const AttachmentPage(
      {super.key, required this.attachment, required this.categories});
  final Attachment attachment;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                try {
                  Receipt? receipt = await ReceiptsDb.get(attachment.id);
                  if (receipt != null) {
                    if (!mounted) return;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ReceiptPage(
                                  expenses: receipt.expenses,
                                  categories: categories,
                                )));
                  }
                } catch (ex) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ErrorsPage(errors: [
                                FailedReceipt(
                                    attachment: attachment,
                                    error: ex.toString())
                              ])));
                }
              },
              icon: const Icon(Icons.scanner))
        ],
      ),
      drawer: const Drawer(),
      body: PdfViewer.openData(attachment.byteArrayContent()),
    );
  }
}
