import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String _fmtKHR(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          // ── Gradient header ───────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ការបញ្ជាទិញរបស់ខ្ញុំ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'តាមដានការដឹកជញ្ជូនរបស់អ្នក',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Order list ────────────────────────────────────────────────
          Expanded(
            child: user == null
                ? const Center(child: Text('Please login first'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFE53935)),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _EmptyOrders();
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) => _OrderCard(doc: docs[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('មិនទាន់មានការបញ្ជាទិញ',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('សូមបញ្ជាទិញដើម្បីមើលការបញ្ជា',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Order card (expandable) ──────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _OrderCard({required this.doc});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  static const _steps = ['Processing', 'On the way', 'Delivered'];
  static const _stepLabels = ['កំពុងដំណើរការ', 'កំពុងដឹក', 'បានដឹកផ្ញើ'];
  static const _stepIcons = [
    Icons.hourglass_top_rounded,
    Icons.local_shipping_outlined,
    Icons.check_circle_outline_rounded,
  ];

  Color _statusColor(String s) {
    switch (s) {
      case 'Delivered':
        return Colors.green;
      case 'On the way':
        return Colors.blue;
      default:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final status = (data['status'] ?? 'Processing') as String;
    final totalUSD = (data['totalUSD'] ?? 0).toDouble();
    final totalKHR = (data['totalKHR'] ?? 0) as int;
    final note = (data['note'] ?? '').toString().trim();
    final stepIndex = _steps.indexOf(status);
    final activeStep = stepIndex < 0 ? 0 : stepIndex;

    String dateStr = 'ថ្មី';
    if (data['createdAt'] != null) {
      final dt = (data['createdAt'] as Timestamp).toDate();
      dateStr =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#ORD-${widget.doc.id.substring(0, 6).toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(dateStr,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_stepIcons[activeStep],
                            size: 13, color: _statusColor(status)),
                        const SizedBox(width: 4),
                        Text(
                          _stepLabels[activeStep],
                          style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Status timeline ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    final lineStep = i ~/ 2;
                    final filled = lineStep < activeStep;
                    return Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: filled
                              ? _statusColor(status)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }
                  final step = i ~/ 2;
                  final done = step <= activeStep;
                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: done
                              ? _statusColor(status)
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow: done
                              ? [
                                  BoxShadow(
                                      color: _statusColor(status)
                                          .withOpacity(0.3),
                                      blurRadius: 6)
                                ]
                              : [],
                        ),
                        child: Icon(_stepIcons[step],
                            size: 15,
                            color:
                                done ? Colors.white : Colors.grey.shade400),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepLabels[step],
                        style: TextStyle(
                            fontSize: 9,
                            color: done
                                ? _statusColor(status)
                                : Colors.grey.shade400,
                            fontWeight: done
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // ── Item thumbnails + total ─────────────────────────────
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ...items.take(4).map((item) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    (item['img'] ?? '').toString(),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.fastfood,
                                        size: 22,
                                        color: Colors.grey),
                                  ),
                                ),
                                if ((item['qty'] ?? 1) > 1)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFE53935),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text(
                                        'x${item['qty']}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )),
                    if (items.length > 4)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '+${items.length - 4}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${totalUSD.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          '${_fmtKHR(totalKHR)} រៀល',
                          style:
                              TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ── Expand toggle ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded ? 'បង្រួម' : 'មើលលម្អិត',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),

            // ── Expanded item detail ────────────────────────────────
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'រាយការណ៍ទំនិញ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final name = (item['name'] ?? '').toString();
                      final qty = (item['qty'] ?? 1) as int;
                      final price = (item['priceUSD'] ?? 0).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Image.asset(
                                (item['img'] ?? '').toString(),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fastfood,
                                    size: 18,
                                    color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(name,
                                    style: const TextStyle(fontSize: 13))),
                            Text(
                              'x$qty  ·  \$${(price * qty).toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (note.isNotEmpty) ...[
                      const Divider(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.sticky_note_2_outlined,
                              size: 15, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(note,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
