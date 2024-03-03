import WASM from '../lib/wasm.mjs';
import { assert } from 'chai';

// This test can be run either in Node.js or in the browser
// npx run test:nodejs
// npx run test:browser

describe('WASM', () => {
  it('can be imported from JS', (done) => {
    WASM
      .then((bindings) => {
        const b = new bindings.Blob;
        assert.instanceOf(b, bindings.Blob);
        done();
      })
      .catch(done);
  });
});
