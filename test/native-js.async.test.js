import { Blob, asyncEnabled } from '../lib/native.cjs';
import { assert } from 'chai';

const no_async = !!process.env.NO_ASYNC;

describe('native', () => {

  it(`async is ${no_async ? 'disabled' : 'enabled'}`, () => {
    assert.strictEqual(asyncEnabled, !no_async);
  });

  describe('async', (done) => {
    if (no_async) return;

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
