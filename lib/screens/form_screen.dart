import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../session.dart';
import '../words.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key, required this.session});

  final Session session;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  static const _navy = Color(0xFF12315F);
  static const _ink = Color(0xFF1B2A4A);
  static const _red = Color(0xFFE14B4B);
  static const _blue = Color(0xFF2F62B5);
  static const _muted = Color(0xFF8B93A7);
  static const _methods = ['Cash', 'Cheque', 'Draft', 'GPay'];

  final _name = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _address3 = TextEditingController();
  final _mobile = TextEditingController();
  final _amount = TextEditingController();
  final _words = TextEditingController();
  final _payment = TextEditingController();
  final _fundraiser = TextEditingController();
  DateTime _date = DateTime.now();
  String _method = 'Cash';
  bool _wordsTouched = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address1.dispose();
    _address2.dispose();
    _address3.dispose();
    _mobile.dispose();
    _amount.dispose();
    _words.dispose();
    _payment.dispose();
    _fundraiser.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    if (_wordsTouched) return;
    final amount = double.tryParse(value.replaceAll(',', ''));
    _words.text = amount == null ? '' : amountInWords(amount);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _shownDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String get _paymentRef {
    final reference = _payment.text.trim();
    if (reference.isEmpty) return _method;
    return '$_method $reference';
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', ''));
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter the full name');
      return;
    }
    if (_address1.text.trim().isEmpty) {
      setState(() => _error = 'Enter the address');
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(_mobile.text.trim())) {
      setState(() => _error = 'Enter a 10-digit mobile number');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (_method != 'Cash' && _payment.text.trim().length < 2) {
      setState(() => _error = 'Enter the cheque, draft or GPay number');
      return;
    }
    if (_fundraiser.text.trim().length < 2) {
      setState(() => _error = 'Enter the fundraising name');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await widget.session.api.createReceipt({
        'date': _isoDate(_date),
        'fullName': _name.text.trim(),
        'addressLines': [_address1.text.trim(), _address2.text.trim(), _address3.text.trim()],
        'mobile': _mobile.text.trim(),
        'amount': amount,
        'amountInWords': _words.text.trim().isEmpty ? amountInWords(amount) : _words.text.trim(),
        'paymentRef': _paymentRef,
        'fundraiserName': _fundraiser.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, receipt.id);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save the slip.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                children: [
                  _topBar(),
                  const SizedBox(height: 14),
                  _dateBar(),
                  const SizedBox(height: 18),
                  _section('Donor details'),
                  _label('Full name'),
                  _box(controller: _name, hint: 'Full name', capitalization: TextCapitalization.words),
                  _label('Address line 1'),
                  _box(controller: _address1, hint: 'House or flat no.'),
                  _label('Address line 2'),
                  _box(controller: _address2, hint: 'Street or colony'),
                  _label('Address line 3'),
                  _box(controller: _address3, hint: 'City and pin code'),
                  _label('Mobile number'),
                  _box(
                    controller: _mobile,
                    hint: '10-digit mobile number',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _section('Payment'),
                  _label('Amount (₹)'),
                  _box(
                    controller: _amount,
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onAmountChanged,
                  ),
                  _label('Amount in words'),
                  _box(controller: _words, hint: 'Amount in words', onChanged: (_) => _wordsTouched = true),
                  _label('Paid by'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final method in _methods)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _methodChip(method),
                          ),
                        ),
                    ],
                  ),
                  _label('Cheque / draft / GPay no.'),
                  _box(controller: _payment, hint: 'Reference number'),
                  const SizedBox(height: 8),
                  _section('Fundraising'),
                  _label('Fundraising name'),
                  _box(controller: _fundraiser, hint: 'Campaign or event name', capitalization: TextCapitalization.words),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Color(0xFF8D2D2D))),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: _busy ? null : _submit,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(_busy ? 'Saving…' : 'Save slip', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Nurturing knowledge, healing communities',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: _navy),
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chapersons Foundations', style: TextStyle(color: _red, fontWeight: FontWeight.w700, fontSize: 12)),
              Text('New slip', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 22, height: 1.05)),
            ],
          ),
        ),
        ClipOval(
          child: ColoredBox(
            color: Colors.white,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Transform.scale(scale: 1.18, child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateBar() {
    return Material(
      color: _navy,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Slip date', style: TextStyle(color: Color(0xFFD5DCEC), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(_shownDate(_date), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(text, style: const TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _box({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textCapitalization: capitalization,
      style: const TextStyle(color: _ink, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0B7C3)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E0D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _blue, width: 1.3),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _methodChip(String method) {
    final selected = _method == method;
    return InkWell(
      onTap: () => setState(() => _method = method),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7EEF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          method,
          style: TextStyle(
            color: selected ? _navy : _muted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
