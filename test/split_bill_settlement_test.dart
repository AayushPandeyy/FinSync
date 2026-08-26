import 'package:finance_tracker/models/SettlementRequest.dart';
import 'package:finance_tracker/models/SplitBill.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bill Aayush paid: 4800 total, split four ways, 1200 each.
SplitBill buildBill({
  Map<String, double> settled = const {},
  Map<String, PendingSettlement> pending = const {},
}) {
  return SplitBill(
    id: 'bill-1',
    title: 'Pokhara trip',
    totalAmount: 4800,
    description: '',
    date: DateTime(2026, 8, 14),
    paidBy: 'payer',
    splitAmounts: const {
      'payer': 1200,
      'a': 1200,
      'b': 1200,
      'c': 1200,
    },
    category: 'Travel',
    participants: const ['payer', 'a', 'b', 'c'],
    settledAmounts: settled,
    participantNames: const {
      'payer': 'Aayush',
      'a': 'Bina',
      'b': 'Chirag',
      'c': 'Dipa',
    },
    pendingSettlements: pending,
  );
}

void main() {
  group('positions on a fresh bill', () {
    final bill = buildBill();

    test('the payer is owed everyone else\'s share, not the total', () {
      expect(bill.totalOwedToPayer, 3600);
      expect(bill.totalRemaining, 3600);
      expect(bill.totalSettled, 0);
    });

    test('the payer is not counted as a payee', () {
      expect(bill.payees, ['a', 'b', 'c']);
      expect(bill.payees.contains('payer'), isFalse);
    });

    test('each payee owes their own share in full', () {
      expect(bill.remainingFor('a'), 1200);
      expect(bill.settleableFor('a'), 1200);
      expect(bill.isSettledFor('a'), isFalse);
    });

    test('nothing is pending and nothing is settled', () {
      expect(bill.hasPendingRequests, isFalse);
      expect(bill.pendingRequestCount, 0);
      expect(bill.isFullySettled, isFalse);
      expect(bill.settlementProgress, 0);
    });
  });

  group('a request awaiting approval', () {
    final bill = buildBill(
      pending: {
        'a': PendingSettlement(
          requestId: 'req-1',
          amount: 500,
          requestedAt: DateTime(2026, 8, 15),
        ),
      },
    );

    test('does not reduce what is owed — only approval moves money', () {
      expect(bill.remainingFor('a'), 1200);
      expect(bill.settledOf('a'), 0);
      expect(bill.totalRemaining, 3600);
    });

    test('does reduce what can go into a further request', () {
      expect(bill.pendingFor('a'), 500);
      expect(bill.settleableFor('a'), 700);
      expect(bill.hasPendingFor('a'), isTrue);
    });

    test('leaves other payees untouched', () {
      expect(bill.hasPendingFor('b'), isFalse);
      expect(bill.settleableFor('b'), 1200);
    });

    test('surfaces to the payer as one review', () {
      expect(bill.pendingRequestCount, 1);
      expect(bill.totalPending, 500);
    });
  });

  group('after a partial approval', () {
    final bill = buildBill(settled: const {'a': 500});

    test('the payee owes the remainder', () {
      expect(bill.settledOf('a'), 500);
      expect(bill.remainingFor('a'), 700);
      expect(bill.settleableFor('a'), 700);
      expect(bill.isSettledFor('a'), isFalse);
    });

    test('the payer is owed less overall', () {
      expect(bill.totalSettled, 500);
      expect(bill.totalRemaining, 3100);
      expect(bill.isFullySettled, isFalse);
    });

    test('progress reflects the whole bill, not one payee', () {
      expect(bill.settlementProgress, closeTo(500 / 3600, 0.0001));
      expect(bill.progressFor('a'), closeTo(500 / 1200, 0.0001));
    });
  });

  group('full settlement', () {
    test('a payee within a paisa of their share counts as clear', () {
      final bill = buildBill(settled: const {'a': 1199.995});
      expect(bill.remainingFor('a'), 0);
      expect(bill.isSettledFor('a'), isTrue);
    });

    test('the bill is settled only once every payee is', () {
      final partial =
          buildBill(settled: const {'a': 1200, 'b': 1200, 'c': 900});
      expect(partial.isFullySettled, isFalse);

      final complete =
          buildBill(settled: const {'a': 1200, 'b': 1200, 'c': 1200});
      expect(complete.isFullySettled, isTrue);
      expect(complete.totalRemaining, 0);
      expect(complete.settlementProgress, 1.0);
    });

    test('the payer having no settled entry does not block completion', () {
      final complete =
          buildBill(settled: const {'a': 1200, 'b': 1200, 'c': 1200});
      expect(complete.settledOf('payer'), 0);
      expect(complete.isFullySettled, isTrue);
    });
  });

  group('names', () {
    test('come off the bill when stamped', () {
      expect(buildBill().nameOf('a'), 'Bina');
    });

    test('fall back for participants written before names existed', () {
      final legacy = SplitBill(
        id: 'old',
        title: 'Old bill',
        totalAmount: 100,
        description: '',
        date: DateTime(2026, 1, 1),
        paidBy: 'payer',
        splitAmounts: const {'payer': 50, 'a': 50},
        category: 'Other',
        participants: const ['payer', 'a'],
      );

      expect(legacy.nameOf('a'), 'Unknown');
      expect(legacy.settledOf('a'), 0);
      expect(legacy.remainingFor('a'), 50);
      expect(legacy.hasPendingRequests, isFalse);
    });
  });

  group('serialization round-trip', () {
    test('keeps settlement state intact', () {
      final original = buildBill(
        settled: const {'a': 500},
        pending: {
          'b': PendingSettlement(
            requestId: 'req-2',
            amount: 300,
            requestedAt: DateTime(2026, 8, 16),
            note: 'sent via eSewa',
          ),
        },
      );

      final restored = SplitBill.fromMap(original.toMap());

      expect(restored.settledOf('a'), 500);
      expect(restored.pendingFor('b'), 300);
      expect(restored.pendingRequestFor('b')!.note, 'sent via eSewa');
      expect(restored.pendingRequestFor('b')!.requestId, 'req-2');
      expect(restored.nameOf('c'), 'Dipa');
      expect(restored.totalRemaining, 3100);
    });
  });
}
