import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/list/master_detail_layout.dart';

void main() {
  group('entityCloseTargetPath (close/back destination)', () {
    test('edit form (slide-over) closes to its detail parent', () {
      expect(
        entityCloseTargetPath(
          basePath: '/clients',
          currentPath: '/clients/c1/edit',
          isFullView: false,
        ),
        '/clients/c1',
      );
    });

    test(
      'edit form (full-width) closes to a full-width detail (?view carries)',
      () {
        expect(
          entityCloseTargetPath(
            basePath: '/clients',
            currentPath: '/clients/c1/edit',
            isFullView: true,
          ),
          '/clients/c1?view=full',
        );
      },
    );

    test('detail closes to the bare list (view flag dropped)', () {
      expect(
        entityCloseTargetPath(
          basePath: '/clients',
          currentPath: '/clients/c1',
          isFullView: true,
        ),
        '/clients',
      );
    });

    test('create closes to the bare list', () {
      expect(
        entityCloseTargetPath(
          basePath: '/clients',
          currentPath: '/clients/new',
          isFullView: false,
        ),
        '/clients',
      );
    });

    test(
      'only the trailing /edit segment is stripped (nested route paths)',
      () {
        expect(
          entityCloseTargetPath(
            basePath: '/settings/company_gateways',
            currentPath: '/settings/company_gateways/g1/edit',
            isFullView: false,
          ),
          '/settings/company_gateways/g1',
        );
      },
    );
  });
}
