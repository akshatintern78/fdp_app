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
  final _name = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _address3 = TextEditingController();
  final _mobile = TextEditingController();
  final _amount = TextEditingController();
  final _words = TextEditingController();
  final _payment = TextEditingController();
  DateTime _date = DateTime.now();
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
    if (_payment.text.trim().length < 2) {
      setState(() => _error = 'Enter the cash, cheque, draft or GPay number');
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
        'paymentRef': _payment.text.trim(),
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
      appBar: AppBar(title: const Text('New slip')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(_shownDate(_date)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: _address1, decoration: const InputDecoration(labelText: 'Address line 1')),
          const SizedBox(height: 12),
          TextField(controller: _address2, decoration: const InputDecoration(labelText: 'Address line 2')),
          const SizedBox(height: 12),
          TextField(controller: _address3, decoration: const InputDecoration(labelText: 'Address line 3')),
          const SizedBox(height: 12),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(labelText: 'Mobile number', counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
            onChanged: _onAmountChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _words,
            decoration: const InputDecoration(labelText: 'Amount in words'),
            onChanged: (_) => _wordsTouched = true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _payment,
            decoration: const InputDecoration(labelText: 'Cash / cheque / draft / GPay no.'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFF8D2D2D))),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Saving…' : 'Save slip'),
          ),
        ],
      ),
    );
  }
}
