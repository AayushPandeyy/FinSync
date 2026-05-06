import 'package:finance_tracker/models/Client.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:flutter/material.dart';

class ClientDetailsPage extends StatelessWidget {
  const ClientDetailsPage({
    super.key,
    required this.client,
  });

  final Client client;

  @override
  Widget build(BuildContext context) {
    final isBusiness = client.clientType.toLowerCase() == 'business';
    final accent =
        isBusiness ? const Color(0xFF7C3AED) : const Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const StandardAppBar(
        title: 'Client Details',
        subtitle: 'Relationship profile',
        useCustomDesign: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(client: client, accent: accent, isBusiness: isBusiness),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Contact Information',
            children: [
              _DetailRow(
                label: 'Contact Person',
                value: _valueOrDash(client.contactPerson),
                icon: Icons.person_outline_rounded,
              ),
              _DetailRow(
                label: 'Email',
                value: _valueOrDash(client.email),
                icon: Icons.alternate_email_rounded,
              ),
              _DetailRow(
                label: 'Phone',
                value: _valueOrDash(client.phoneNumber),
                icon: Icons.phone_outlined,
              ),
              _DetailRow(
                label: 'Address',
                value: _valueOrDash(client.address),
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Business Preferences',
            children: [
              _DetailRow(
                label: 'Client Type',
                value: isBusiness ? 'Business' : 'Individual',
                icon: Icons.category_outlined,
              ),
              _DetailRow(
                label: 'Currency',
                value: _valueOrDash(client.currencyPreference),
                icon: Icons.currency_exchange_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Notes',
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _valueOrDash(client.notes),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _valueOrDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.client,
    required this.accent,
    required this.isBusiness,
  });

  final Client client;
  final Color accent;
  final bool isBusiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isBusiness ? Icons.apartment_rounded : Icons.person_rounded,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.clientName.trim().isEmpty
                      ? 'Unnamed Client'
                      : client.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isBusiness ? 'Business Client' : 'Individual Client',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
