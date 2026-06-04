import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/domain/tasks/task_rate.dart';

void main() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Task taskWithRate(Decimal rate) => Task(
    id: 't',
    number: '',
    description: '',
    rate: rate,
    invoiceId: '',
    clientId: '',
    projectId: '',
    statusId: '',
    statusOrder: 0,
    assignedUserId: '',
    timeLog: const <TimeEntry>[],
    customValue1: '',
    customValue2: '',
    customValue3: '',
    customValue4: '',
    updatedAt: epoch,
    createdAt: epoch,
    archivedAt: null,
    isDeleted: false,
  );

  Company companyWithRate(double? rate) => Company(
    id: 'co',
    settings: CompanySettingsApi(defaultTaskRate: rate),
  );

  test('explicit task rate wins over the company default', () {
    expect(
      resolveTaskRate(
        task: taskWithRate(Decimal.fromInt(50)),
        company: companyWithRate(100),
      ),
      Decimal.fromInt(50),
    );
  });

  test('rate 0 falls back to company default_task_rate (the A2 bug)', () {
    expect(
      resolveTaskRate(
        task: taskWithRate(Decimal.zero),
        company: companyWithRate(100),
      ),
      Decimal.fromInt(100),
    );
  });

  test('rate 0 with no inherited default stays 0', () {
    expect(resolveTaskRate(task: taskWithRate(Decimal.zero)), Decimal.zero);
    expect(
      resolveTaskRate(
        task: taskWithRate(Decimal.zero),
        company: companyWithRate(null),
      ),
      Decimal.zero,
    );
    expect(
      resolveTaskRate(
        task: taskWithRate(Decimal.zero),
        company: companyWithRate(0),
      ),
      Decimal.zero,
    );
  });
}
