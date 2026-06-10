import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';

class TenantPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bill;
  const TenantPaymentScreen({super.key, required this.bill});

  @override
  State<TenantPaymentScreen> createState() => _TenantPaymentScreenState();
}

class _TenantPaymentScreenState extends State<TenantPaymentScreen> {
  String _selectedMethod = 'QRIS';
  bool _processing = false;

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'QRIS',
      'label': 'QRIS',
      'subtitle': 'Scan QR with any app',
      'icon': Icons.qr_code_rounded,
      'color': const Color(0xFF1565C0),
    },
    {
      'id': 'OVO',
      'label': 'OVO',
      'subtitle': 'Pay with OVO balance',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF6A1B9A),
    },
    {
      'id': 'DANA',
      'label': 'DANA',
      'subtitle': 'Pay with DANA balance',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF0288D1),
    },
    {
      'id': 'GoPay',
      'label': 'GoPay',
      'subtitle': 'Pay with GoPay balance',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF2E7D32),
    },
    {
      'id': 'Bank Transfer',
      'label': 'Bank Transfer',
      'subtitle': 'Manual bank transfer',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFFE65100),
    },
  ];

  String _formatRupiah(dynamic amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(double.parse(amount.toString()));
  }

  Future<void> _processPayment() async {
    setState(() => _processing = true);

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    final tenant = Provider.of<TenantProvider>(context, listen: false);
    final success =
    await tenant.payBill(widget.bill['id'], _selectedMethod);

    if (!mounted) return;
    setState(() => _processing = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF2E7D32), size: 44),
              ),
              const SizedBox(height: 16),
              const Text('Payment Successful!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'You paid ${_formatRupiah(widget.bill['total_amount'])} via $_selectedMethod',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.bill['total_amount'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 20),
                  _SummaryRow(
                      label: 'Billing Month',
                      value: widget.bill['billing_month']),
                  _SummaryRow(
                      label: 'Base Rent',
                      value:
                      _formatRupiah(widget.bill['base_amount'])),
                  if (double.parse(
                      widget.bill['addon_amount'].toString()) >
                      0)
                    _SummaryRow(
                        label: 'Add-ons',
                        value: _formatRupiah(
                            widget.bill['addon_amount'])),
                  if (double.parse(
                      widget.bill['penalty_amount'].toString()) >
                      0)
                    _SummaryRow(
                        label: 'Late Penalty',
                        value: _formatRupiah(
                            widget.bill['penalty_amount']),
                        isRed: true),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _formatRupiah(total),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1565C0)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment methods
            const Text('Select Payment Method',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),

            ..._methods.map((method) => GestureDetector(
              onTap: () =>
                  setState(() => _selectedMethod = method['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedMethod == method['id']
                        ? method['color']
                        : Colors.grey[200]!,
                    width:
                    _selectedMethod == method['id'] ? 2 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (method['color'] as Color)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(method['icon'] as IconData,
                          color: method['color'] as Color,
                          size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(method['label'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(method['subtitle'],
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_selectedMethod == method['id'])
                      Icon(Icons.check_circle,
                          color: method['color'] as Color),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),

            // Simulated notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment is simulated. Real gateway (Midtrans/Xendit) can be connected later.',
                      style:
                      TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _processing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _processing
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Processing payment...',
                        style: TextStyle(fontSize: 16)),
                  ],
                )
                    : const Text('Pay Now',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isRed;
  const _SummaryRow(
      {required this.label, required this.value, this.isRed = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: isRed ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}