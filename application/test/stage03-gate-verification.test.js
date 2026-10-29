import { test } from 'node:test';
import assert from 'node:assert/strict';

test('temporary Stage 03 required-check enforcement verification', () => {
  assert.fail('Intentional failure: verify the required PR check blocks this commit.');
});
