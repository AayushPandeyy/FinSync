import 'package:finance_tracker/pages/personalMode/friendsPage/FriendDetailsPage.dart';
import 'package:finance_tracker/service/FriendsFirestoreService.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final Friendsfirestoreservice _friendsService = Friendsfirestoreservice();
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _acceptRequest(String friendshipId) async {
    try {
      await _friendsService.acceptRequest(friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text('Friend request accepted.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to accept request.')),
        );
    }
  }

  Future<void> _rejectRequest(String friendshipId) async {
    try {
      await _friendsService.rejectRequest(friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text('Friend request rejected.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to reject request.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: const StandardAppBar(
          title: 'Friends',
          subtitle: 'Manage your friend connections',
          useCustomDesign: true,
        ),
        body: const Center(
          child: Text(
            'Please sign in to view friends.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: const StandardAppBar(
          title: 'Friends',
          subtitle: 'Manage your friend connections',
          useCustomDesign: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _search = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _FriendsTabContent(
                friendsService: _friendsService,
                currentUid: currentUid,
                search: _search,
                onAcceptRequest: _acceptRequest,
                onRejectRequest: _rejectRequest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsTabContent extends StatelessWidget {
  const _FriendsTabContent({
    required this.friendsService,
    required this.currentUid,
    required this.search,
    required this.onAcceptRequest,
    required this.onRejectRequest,
  });

  final Friendsfirestoreservice friendsService;
  final String currentUid;
  final String search;
  final Future<void> Function(String friendshipId) onAcceptRequest;
  final Future<void> Function(String friendshipId) onRejectRequest;

  bool _matchesQuery(Map<String, dynamic> user) {
    if (search.isEmpty) return true;
    final username = (user['username']?.toString() ?? '').toLowerCase();
    final email = (user['email']?.toString() ?? '').toLowerCase();
    return username.contains(search) || email.contains(search);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendsService.getFriends(currentUid),
      builder: (context, friendSnapshot) {
        if (friendSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendSnapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load friends',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }

        final friendships =
            friendSnapshot.data ?? const <Map<String, dynamic>>[];
        final friendIds = friendships
            .map((friendship) {
              final requesterId = friendship['requesterId']?.toString() ?? '';
              final receiverId = friendship['receiverId']?.toString() ?? '';
              return requesterId == currentUid ? receiverId : requesterId;
            })
            .where((id) => id.isNotEmpty)
            .toSet();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: friendsService.getOutgoingRequests(currentUid),
          builder: (context, outgoingSnapshot) {
            final outgoing =
                outgoingSnapshot.data ?? const <Map<String, dynamic>>[];
            final requestedUserIds = outgoing
                .map((request) => request['receiverId']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: friendsService.getIncomingRequests(currentUid),
              builder: (context, incomingSnapshot) {
                final incoming =
                    incomingSnapshot.data ?? const <Map<String, dynamic>>[];
                final receivedUserIds = incoming
                    .map((request) => request['requesterId']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toSet();
                final incomingByRequester = {
                  for (final request in incoming)
                    (request['requesterId']?.toString() ?? ''):
                        (request['id']?.toString() ?? ''),
                };

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: friendsService.getUsers(),
                  builder: (context, usersSnapshot) {
                    if (usersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (usersSnapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Failed to load user details',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      );
                    }

                    final searchableUsers =
                        (usersSnapshot.data ?? const <Map<String, dynamic>>[])
                            .where((user) {
                              final uid = user['uid']?.toString() ?? '';
                              return uid.isNotEmpty && uid != currentUid;
                            })
                            .where(_matchesQuery)
                            .toList();

                    final friendUsers = searchableUsers.where((user) {
                      final uid = user['uid']?.toString() ?? '';
                      return friendIds.contains(uid);
                    }).toList();

                    final requestedUsers = searchableUsers.where((user) {
                      final uid = user['uid']?.toString() ?? '';
                      return requestedUserIds.contains(uid);
                    }).toList();

                    final receivedUsers = searchableUsers.where((user) {
                      final uid = user['uid']?.toString() ?? '';
                      return receivedUserIds.contains(uid);
                    }).toList();

                    Widget buildTileForUser(Map<String, dynamic> user) {
                      final uid = user['uid']?.toString() ?? '';
                      final isFriend = friendIds.contains(uid);
                      final isRequested = requestedUserIds.contains(uid);
                      final isReceived = receivedUserIds.contains(uid);

                      Widget trailing;
                      if (isFriend) {
                        trailing = const _StatusPill(
                          label: 'Friend',
                          bgColor: Color(0xFFEFF6FF),
                          fgColor: Color(0xFF1D4ED8),
                        );
                      } else if (isRequested) {
                        trailing = const _StatusPill(
                          label: 'Requested',
                          bgColor: Color(0xFFF1F5F9),
                          fgColor: Color(0xFF475569),
                        );
                      } else if (isReceived) {
                        final friendshipId = incomingByRequester[uid] ?? '';
                        trailing = _IncomingRequestActions(
                          friendshipId: friendshipId,
                          onAccept: onAcceptRequest,
                          onReject: onRejectRequest,
                        );
                      } else {
                        trailing = _AddAsFriendButton(
                          currentUid: currentUid,
                          receiverUid: uid,
                        );
                      }

                      return _UserTile(
                        user: user,
                        trailing: trailing,
                      );
                    }

                    if (search.isNotEmpty) {
                      return _UserListView(
                        users: searchableUsers,
                        emptyMessage: 'No users found for your search',
                        itemBuilder: buildTileForUser,
                      );
                    }

                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TabBar(
                            dividerColor: Colors.transparent,
                            indicatorColor: const Color(0xFF2563EB),
                            labelColor: const Color(0xFF2563EB),
                            unselectedLabelColor: const Color(0xFF64748B),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            tabs: [
                              Tab(text: 'Friends (${friendUsers.length})'),
                              Tab(text: 'Requested (${requestedUsers.length})'),
                              Tab(text: 'Received (${receivedUsers.length})'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _UserListView(
                                users: friendUsers,
                                emptyMessage: 'No friends found',
                                itemBuilder: buildTileForUser,
                              ),
                              _UserListView(
                                users: requestedUsers,
                                emptyMessage: 'No pending requests sent',
                                itemBuilder: (user) => _UserTile(
                                  user: user,
                                  trailing: const _StatusPill(
                                    label: 'Requested',
                                    bgColor: Color(0xFFF1F5F9),
                                    fgColor: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              _UserListView(
                                users: receivedUsers,
                                emptyMessage: 'No pending requests received',
                                itemBuilder: (user) {
                                  final uid = user['uid']?.toString() ?? '';
                                  return _UserTile(
                                    user: user,
                                    trailing: _IncomingRequestActions(
                                      friendshipId:
                                          incomingByRequester[uid] ?? '',
                                      onAccept: onAcceptRequest,
                                      onReject: onRejectRequest,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _UserListView extends StatelessWidget {
  const _UserListView({
    required this.users,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final List<Map<String, dynamic>> users;
  final String emptyMessage;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => itemBuilder(users[index]),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.trailing});

  final Map<String, dynamic> user;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final username = user['username']?.toString().trim();
    final email = user['email']?.toString().trim();
    final displayName =
        (username == null || username.isEmpty) ? 'Unknown user' : username;
    final displayEmail =
        (email == null || email.isEmpty) ? 'No email available' : email;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendDetailsPage(user: user),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9ECF0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fgColor,
        ),
      ),
    );
  }
}

class _IncomingRequestActions extends StatefulWidget {
  const _IncomingRequestActions({
    required this.friendshipId,
    required this.onAccept,
    required this.onReject,
  });

  final String friendshipId;
  final Future<void> Function(String friendshipId) onAccept;
  final Future<void> Function(String friendshipId) onReject;

  @override
  State<_IncomingRequestActions> createState() =>
      _IncomingRequestActionsState();
}

class _IncomingRequestActionsState extends State<_IncomingRequestActions> {
  bool _loading = false;

  Future<void> _handle(
      Future<void> Function(String friendshipId) action) async {
    if (_loading || widget.friendshipId.isEmpty) return;
    setState(() {
      _loading = true;
    });
    await action(widget.friendshipId);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _handle(widget.onAccept),
          icon: const Icon(Icons.check_circle_outline_rounded),
          color: const Color(0xFF16A34A),
          iconSize: 20,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          tooltip: 'Accept',
        ),
        IconButton(
          onPressed: () => _handle(widget.onReject),
          icon: const Icon(Icons.cancel_outlined),
          color: const Color(0xFFDC2626),
          iconSize: 20,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          tooltip: 'Reject',
        ),
      ],
    );
  }
}

class _AddAsFriendButton extends StatefulWidget {
  const _AddAsFriendButton({
    required this.currentUid,
    required this.receiverUid,
  });

  final String currentUid;
  final String receiverUid;

  @override
  State<_AddAsFriendButton> createState() => _AddAsFriendButtonState();
}

class _AddAsFriendButtonState extends State<_AddAsFriendButton> {
  final Friendsfirestoreservice _friendsService = Friendsfirestoreservice();
  bool _isSending = false;
  bool _sentLocally = false;

  Future<void> _sendRequest() async {
    if (_isSending || _sentLocally || widget.receiverUid.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _friendsService.sendFriendRequest(
        requesterId: widget.currentUid,
        receiverId: widget.receiverUid,
      );

      if (!mounted) return;
      setState(() {
        _sentLocally = true;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Friend request sent.')),
        );
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
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: (_isSending || _sentLocally) ? null : _sendRequest,
      icon: _isSending
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_sentLocally ? Icons.check_rounded : Icons.add_rounded,
              size: 14),
      label: Text(_sentLocally ? 'Requested' : 'Add as friend'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 30),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
