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
  static const _navy = Color(0xFF16325C);
  static const _ink = Color(0xFF1B2A4A);
  static const _red = Color(0xFFE14B4B);
  static const _blue = Color(0xFF2F62B5);
  static const _card = Color(0xFF12315F);
  static const _muted = Color(0xFF8B93A7);

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

  Future<void> _openSlip(Receipt receipt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(session: widget.session, receiptId: receipt.id)),
    );
  }

  String _money(double amount) {
    final hasPaise = (amount * 100).round() % 100 != 0;
    final digits = NumberFormat.decimalPattern('en_IN');
    if (hasPaise) digits.minimumFractionDigits = 2;
    return '₹${digits.format(amount)}';
  }

  String _when(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  double get _total => _receipts.fold(0, (sum, receipt) => sum + receipt.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    _summary(),
                    const SizedBox(height: 22),
                    const Text(
                      'Recent slips',
                      style: TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(_error!))
                    else if (_receipts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No slips yet. Create one to get a receipt.'),
                      )
                    else
                      _leadTable(_receipts),
                  ],
                ),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        ClipOval(
          child: ColoredBox(
            color: Colors.white,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Transform.scale(scale: 1.18, child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chapersons Foundations',
                style: TextStyle(color: _red, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                widget.session.user?.name ?? 'Chapersons',
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 20, height: 1.1),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(side: BorderSide(color: Color(0xFFD5D8E0))),
          child: IconButton(
            tooltip: 'Sign out',
            onPressed: widget.session.logout,
            icon: const Icon(Icons.logout_rounded, color: _navy, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 132,
        color: _card,
        child: Stack(
          children: [
            Positioned(right: -18, top: -28, child: _blob(86, const Color(0xFFE14B4B))),
            Positioned(right: 18, bottom: -22, child: _blob(64, const Color(0xFF2F62B5))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total collected', style: TextStyle(color: Color(0xFFD5DCEC), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _money(_total),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _pill('${_receipts.length} slips', _blue, Colors.white),
                      const SizedBox(width: 8),
                      _pill('Top', Colors.white, _ink),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _pill(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _leadTable(List<Receipt> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E1D8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const ColoredBox(
            color: Color(0xFFF3F6FB),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text('Lead', style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 12))),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.only(left: 18),
                      child: Text('Fundraising', style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          ...rows.map(_tableRow),
        ],
      ),
    );
  }

  Widget _tableRow(Receipt receipt) {
    final fundraiser = receipt.fundraiserName.isEmpty ? '—' : receipt.fundraiserName;
    return InkWell(
      onTap: () => _openSlip(receipt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEDE8E0)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receipt.fullName, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Slip ${receipt.serialNo}, ${_when(receipt.date)}', style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(fundraiser, style: const TextStyle(color: _ink, fontSize: 13, height: 1.25)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _money(receipt.amount),
                textAlign: TextAlign.right,
                style: const TextStyle(color: _red, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _openNew,
            icon: const Icon(Icons.note_add_outlined, size: 18),
            label: const Text('New slip', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
