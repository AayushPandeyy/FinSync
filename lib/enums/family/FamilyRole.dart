/// Role a person holds inside a family workspace.
///
/// `admin` may add/approve members, change designations and delete the family.
/// `member` may only add family income, expenses and subscriptions.
enum FamilyRole {
  admin,
  member,
}

extension FamilyRoleX on FamilyRole {
  String get value => name;

  String get label {
    switch (this) {
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.member:
        return 'Member';
    }
  }

  static FamilyRole fromValue(String? value) {
    return value == FamilyRole.admin.name ? FamilyRole.admin : FamilyRole.member;
  }
}

/// Lifecycle of a request created when somebody joins with a family code.
enum JoinRequestStatus {
  pending,
  approved,
  rejected,
}

extension JoinRequestStatusX on JoinRequestStatus {
  String get value => name;

  static JoinRequestStatus fromValue(String? value) {
    switch (value) {
      case 'approved':
        return JoinRequestStatus.approved;
      case 'rejected':
        return JoinRequestStatus.rejected;
      default:
        return JoinRequestStatus.pending;
    }
  }
}

/// Suggested designations shown when creating a family or requesting to join.
/// Free text is still allowed — this is only a convenience list.
const List<String> kFamilyDesignations = [
  'Father',
  'Mother',
  'Son',
  'Daughter',
  'Husband',
  'Wife',
  'Brother',
  'Sister',
  'Grandfather',
  'Grandmother',
  'Guardian',
  'Other',
];
