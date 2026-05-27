import 'community_user.dart';

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.status,
    required this.requesterId,
    required this.addresseeId,
    required this.isIncoming,
    required this.isOutgoing,
    required this.user,
  });

  final String id;
  final String status;
  final String requesterId;
  final String addresseeId;
  final bool isIncoming;
  final bool isOutgoing;
  final CommunityUser user;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      requesterId: json['requesterId'] as String? ?? '',
      addresseeId: json['addresseeId'] as String? ?? '',
      isIncoming: json['isIncoming'] as bool? ?? false,
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      user: CommunityUser.fromJson(
        Map<String, dynamic>.from((json['user'] as Map?) ?? const {}),
      ),
    );
  }
}

class FriendRequestsResponse {
  const FriendRequestsResponse({
    required this.incoming,
    required this.outgoing,
  });

  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;

  factory FriendRequestsResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestsResponse(
      incoming: ((json['incoming'] as List?) ?? const [])
          .map(
            (item) => FriendRequest.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      outgoing: ((json['outgoing'] as List?) ?? const [])
          .map(
            (item) => FriendRequest.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
