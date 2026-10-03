import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models.dart';
import '../slip_layout.dart';

class SlipView extends StatelessWidget {
  const SlipView({super.key, required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / SlipLayout.width;
        final lines = receipt.addressLines;
        return SizedBox(
          width: width,
          height: SlipLayout.height * scale,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/slip.jpg', fit: BoxFit.fill),
              _field(scale, SlipLayout.date, _displayDate(receipt.date)),
              _field(scale, SlipLayout.serialNo, '${receipt.serialNo}'),
              _field(scale, SlipLayout.fullName, receipt.fullName),
              _field(scale, SlipLayout.address[0], lines[0]),
              _field(scale, SlipLayout.address[1], lines[1]),
              _field(scale, SlipLayout.address[2], lines[2]),
              _field(scale, SlipLayout.mobile, receipt.mobile),
              _field(scale, SlipLayout.amount, _displayAmount(receipt.amount)),
              _field(scale, SlipLayout.amountInWords, receipt.amountInWords),
              _field(scale, SlipLayout.paymentRef, receipt.paymentRef),
              if (receipt.signatureBase64 != null)
                _signature(scale, base64Decode(receipt.signatureBase64!)),
            ],
          ),
        );
      },
    );
  }

  Widget _field(double scale, SlipField field, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    final maxWidth = (field.maxX - field.x) * scale;
    return Positioned(
      left: field.x * scale,
      top: field.top * scale,
      width: maxWidth,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: TextStyle(
          color: const Color(0xFF1A1A1A),
          fontSize: field.size * scale,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  Widget _signature(double scale, Uint8List bytes) {
    return Positioned(
      left: SlipLayout.signature.x * scale,
      top: SlipLayout.signature.top * scale,
      width: (SlipLayout.signature.maxX - SlipLayout.signature.x) * scale,
      height: SlipLayout.signatureHeight * scale,
      child: Image.memory(bytes, fit: BoxFit.contain, alignment: Alignment.centerLeft),
    );
  }
}

String _displayDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _displayAmount(double amount) {
  final hasPaise = (amount * 100).round() % 100 != 0;
  final fixed = hasPaise ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
  final bits = fixed.split('.');
  final whole = _indianGroup(bits[0]);
  return bits.length == 2 ? '$whole.${bits[1]}' : whole;
}

String _indianGroup(String digits) {
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final chunks = <String>[];
  var rest = head;
  while (rest.length > 2) {
    chunks.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) chunks.insert(0, rest);
  return '${chunks.join(',')},$tail';
}
