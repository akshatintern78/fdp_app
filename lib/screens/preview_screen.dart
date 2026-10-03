import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import '../slip_layout.dart';
import '../pdf_file.dart';
import '../widgets/slip_view.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.session, required this.receiptId});

  final Session session;
  final int receiptId;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Receipt? _receipt;
  String? _error;
  bool _downloading = false;
  final _transform = TransformationController();
  bool _fitted = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final receipt = await widget.session.api.receipt(widget.receiptId);
      if (!mounted) return;
      setState(() => _receipt = receipt);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not open this slip.');
    }
  }

  void _fit(double viewportWidth, double viewportHeight) {
    if (_fitted || viewportWidth <= 0 || viewportHeight <= 0) return;
    _fitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      const slipWidth = 1400.0;
      final slipHeight = slipWidth * SlipLayout.height / SlipLayout.width;
      final scale = math.min((viewportWidth - 12) / slipWidth, (viewportHeight - 12) / slipHeight);
      _transform.value = Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
    });
  }

  Future<void> _download() async {
    final receipt = _receipt;
    if (receipt == null) return;
    setState(() => _downloading = true);
    try {
      final bytes = await widget.session.api.receiptPdf(receipt.id);
      await saveAndOpenPdf(bytes, 'receipt-${receipt.serialNo}.pdf');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the PDF.')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    return Scaffold(
      appBar: AppBar(
        title: Text(receipt == null ? 'Slip' : 'S. No ${receipt.serialNo}'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: receipt == null || _downloading ? null : _download,
            icon: _downloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: receipt == null
          ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Pinch to zoom. The saved slip stays in your list after download.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _fit(constraints.maxWidth, constraints.maxHeight);
                      return InteractiveViewer(
                        transformationController: _transform,
                        minScale: 0.15,
                        maxScale: 3,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: SizedBox(
                          width: 1400,
                          height: 1400 * SlipLayout.height / SlipLayout.width,
                          child: SlipView(receipt: receipt),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _downloading ? null : _download,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(_downloading ? 'Preparing PDF…' : 'Download PDF'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
