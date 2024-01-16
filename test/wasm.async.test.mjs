import WASM from '../lib/wasm.mjs';
import { assert } from 'chai';

describe('WASM', () => {
  let Blob;
  before('load WASM', (done) => {
    WASM.then((bindings) => {
      Blob = bindings.Blob;
      done();
    })
  });

  describe('async', (done) => {
    it('write into an existing ArrayBuffer', () => {
      const blob = new Blob(10);
      const ab = new ArrayBuffer(10);
      blob.Fill(42);
      blob.WriteAsync(ab).then(() => {
        const view = new Uint8Array(ab);
        view.forEach((v) => assert.strictEqual(v, 42));
        done();
      }).catch(done);
    });

    it('try funny things', (done) => {
      const blob = new Blob(12);
      const ab = new ArrayBuffer(8);
      blob.WriteAsync(ab).then(() => {
        done('funny things');
      }).catch((e) => {
        assert.match(e.message, /Sizes must match/);
        done();
      });
    });

  });

});
