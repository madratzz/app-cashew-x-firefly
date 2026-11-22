import 'package:budget/firefly/api/models/bill.dart';
import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and serializes all five bill frequencies', () {
    const frequencies = [
      'weekly',
      'monthly',
      'quarterly',
      'half-year',
      'yearly'
    ];
    for (final (index, wire) in frequencies.indexed) {
      final bill = FireflyBill.fromJson({
        'id': 7,
        'attributes': {
          'name': 'Example bill',
          'amount_min': '7.50',
          'amount_max': '12.30',
          'repeat_freq': wire,
          'pay_dates': ['2026-11-28T10:00:00+00:00'],
          'paid_dates': [
            {'date': '2026-11-21T10:00:00+00:00'}
          ],
        },
      });
      expect(bill.id, '7');
      expect(bill.frequency, FireflyBillFrequency.values[index]);
      expect(bill.frequency!.wireValue, wire);
      expect(bill.amountMin, 7.5);
      expect(bill.amountMax, 12.3);
      expect(bill.payDates.single.toUtc(), DateTime.utc(2026, 11, 28, 10));
      expect(bill.paidDates.single.toUtc(), DateTime.utc(2026, 11, 21, 10));
      expect(bill.toWriteJson(), {
        'name': 'Example bill',
        'amount_min': '7.50',
        'amount_max': '12.30',
        'repeat_freq': wire,
      });
    }
  });

  test('parses and serializes all five recurrence repetition types', () {
    const repetitions = [
      ('daily', ''),
      ('weekly', '3'),
      ('ndom', '2,3'),
      ('monthly', '15'),
      ('yearly', '2026-11-15'),
    ];
    for (final (index, (type, moment)) in repetitions.indexed) {
      final repetition = FireflyRepetition({
        'id': '3',
        'type': type,
        'moment': moment,
        'skip': 1,
        'weekend': 4,
        'description': 'Generated',
        'occurrences': ['2026-11-27T00:00:00+14:00'],
      });
      expect(repetition.type, FireflyRepetitionType.values[index]);
      expect(repetition.moment, moment);
      expect(repetition.skip, 1);
      expect(repetition.weekend, 4);
      expect(repetition.occurrences, [DateTime(2026, 11, 27)]);
      expect(repetition.toWriteJson(), {
        'type': type,
        'moment': moment,
        'skip': 1,
        'weekend': 4,
      });
    }
  });

  test('upcoming dates come from active server repetitions', () {
    final recurrence = FireflyRecurrence.fromJson({
      'id': '4',
      'attributes': {
        'title': 'Example recurrence',
        'active': true,
        'first_date': '2026-11-01',
        'repetitions': [
          {
            'type': 'weekly',
            'occurrences': ['2026-11-15', '2026-11-29', '2026-11-22'],
          },
          {
            'type': 'monthly',
            'occurrences': [null, '2026-11-22'],
          },
        ],
      },
    });
    final today = DateTime(2026, 11, 22, 14);
    expect(recurrence.firstDate, DateTime(2026, 11, 1));
    expect(recurrence.upcomingOccurrences(from: today), [
      DateTime(2026, 11, 22),
      DateTime(2026, 11, 29),
    ]);
    expect(recurrence.nextOccurrence(from: today), DateTime(2026, 11, 22));
    expect(recurrence.nextOccurrence(from: DateTime(2026, 12)), isNull);
    expect(
      FireflyRecurrence(id: '4', attributes: {
        ...recurrence.attributes,
        'active': false,
      }).upcomingOccurrences(from: today),
      isEmpty,
    );
  });

  test('recurrence template IDs are writeable only on updates', () {
    const recurrence = FireflyRecurrence(id: '5', attributes: {
      'title': 'Example recurrence',
      'type': 'withdrawal',
      'latest_date': '2026-11-15',
      'transactions': [
        {
          'id': '15',
          'source_id': '1',
          'destination_id': '2',
          'source_name': 'Example wallet',
          'subscription_id': '3',
          'bill_id': '9',
        },
      ],
    });
    expect(recurrence.toWriteJson(), {
      'title': 'Example recurrence',
      'type': 'withdrawal',
      'transactions': [
        {'source_id': '1', 'destination_id': '2', 'bill_id': '3'},
      ],
    });
    expect(recurrence.toWriteJson(updating: true), {
      'title': 'Example recurrence',
      'transactions': [
        {'id': '15', 'source_id': '1', 'destination_id': '2', 'bill_id': '3'},
      ],
    });
  });
}
