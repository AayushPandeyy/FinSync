import 'package:finance_tracker/service/FriendsFirestoreService.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendDetailsPage extends StatefulWidget {
  const FriendDetailsPage({
    super.key,
    required this.user,
  });

  final Map<String, dynamic> user;

  @override
  State<FriendDetailsPage> createState() => _FriendDetailsPageState();
}

class _FriendDetailsPageState extends State<FriendDetailsPage> {
  final Friendsfirestoreservice _friendsService = Friendsfirestoreservice();
  bool _isActionLoading = false;

  String _safe(dynamic value) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? 'Not provided' : parsed;
  }

  Future<void> _sendFriendRequest({
    required String currentUid,
    required String targetUid,
  }) async {
    if (_isActionLoading || currentUid.isEmpty || targetUid.isEmpty) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await _friendsService.sendFriendRequest(
        requesterId: currentUid,
        receiverId: targetUid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Friend request sent.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to send friend request.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _removeFriend(String friendshipId) async {
    if (_isActionLoading || friendshipId.isEmpty) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await _friendsService.removeFriend(friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Friend removed.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to remove friend.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _safe(widget.user['username']);
    final email = _safe(widget.user['email']);
    final phone = _safe(widget.user['phone']);
    final address = _safe(widget.user['address']);
    final targetUid = widget.user['uid']?.toString() ?? '';
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const StandardAppBar(
        title: 'Friend Details',
        subtitle: 'Profile overview',
        useCustomDesign: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            name: username,
            email: email,
          ),
          const SizedBox(height: 12),
          if (currentUid.isNotEmpty && targetUid.isNotEmpty)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _friendsService.getFriends(currentUid),
              builder: (context, snapshot) {
                final friendships =
                    snapshot.data ?? const <Map<String, dynamic>>[];

                String friendshipId = '';
                for (final friendship in friendships) {
                  final requesterId =
                      friendship['requesterId']?.toString() ?? '';
                  final receiverId = friendship['receiverId']?.toString() ?? '';

                  if ((requesterId == currentUid && receiverId == targetUid) ||
                      (requesterId == targetUid && receiverId == currentUid)) {
                    friendshipId = friendship['id']?.toString() ?? '';
                    break;
                  }
                }

                final isFriend = friendshipId.isNotEmpty;

                if (isFriend) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isActionLoading
                          ? null
                          : () => _removeFriend(friendshipId),
                      icon: _isActionLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_remove_alt_1_rounded),
                      label: Text(
                          _isActionLoading ? 'Removing...' : 'Remove friend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isActionLoading
                        ? null
                        : () => _sendFriendRequest(
                              currentUid: currentUid,
                              targetUid: targetUid,
                            ),
                    icon: _isActionLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label:
                        Text(_isActionLoading ? 'Sending...' : 'Add as friend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Contact Information',
            children: [
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Name',
                value: username,
              ),
              _DetailRow(
                icon: Icons.alternate_email_rounded,
                label: 'Email',
                value: email,
              ),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: phone,
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: address,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.email});

  final String name;
  final String email;

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
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
