import { test } from 'node:test';

test('intentional failure verifies runner exit status', () => {
  throw new Error('Expected failure: this fixture must exit with code 1.');
});
