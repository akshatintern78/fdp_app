import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import 'form_screen.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});

  final Session session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Receipt> _receipts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final receipts = await widget.session.api.receipts();
      if (!mounted) return;
      setState(() => _receipts = receipts);
    } on ApiException catch (error) {
      if (error.status == 401) {
        await widget.session.logout();
        return;
      }
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load your slips.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNew() async {
    final id = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => FormScreen(session: widget.session)),
    );
    if (!mounted || id == null) return;
    await _load();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(session: widget.session, receiptId: id)),
    );
  }

  String _money(double amount) {
    final hasPaise = (amount * 100).round() % 100 != 0;
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: hasPaise ? 2 : 0).format(amount);
  }

  String _date(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.user?.name ?? 'Slips'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.session.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('New slip'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                ],
              )
            : _receipts.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No slips yet. Create one to get a receipt.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: _receipts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final receipt = _receipts[index];
                  return Card(
                    child: ListTile(
                      title: Text(receipt.fullName),
                      subtitle: Text('S. No ${receipt.serialNo}  ·  ${_date(receipt.date)}'),
                      trailing: Text(_money(receipt.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewScreen(session: widget.session, receiptId: receipt.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
