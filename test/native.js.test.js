import native from '../lib/native.cjs';
import { assert } from 'chai';

// This test is exclusive to Node.js
// npx run test:nodejs

describe('native', () => {
  it('can be imported from JS', () => {
        const b = new native.Blob;
        assert.instanceOf(b, native.Blob);
  });
});
