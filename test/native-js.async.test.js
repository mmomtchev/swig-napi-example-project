import { Blob, asyncEnabled } from '../lib/native.cjs';
import * as dll from '../lib/native.cjs';
import * as process from 'node:process';
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

    describe('pass a callback to be called from C++', () => {
      it('nominal', (done) => {
        dll.GiveMeFiveAsync((pass, name) => {
          assert.strictEqual(pass, 420);
          assert.isString(name);
          return 'sent from JS ' + name;
        }).then((r) => {
          assert.isString(r);
          assert.strictEqual(r, 'received from JS: sent from JS with cheese');
          done();
        }).catch(done);
      });

      it('exception cases', (done) => {
        dll.GiveMeFiveAsync(() => {
          throw new Error('420 failed');
        })
          .catch((e) => {
            assert.match(e.message, /420 failed/);
          })
          .then(() => dll.GiveMeFiveAsync(() => Infinity))
          .catch((e) => {
            assert.match(e.message, /callback return value of type 'std::string'/);
          })
          .then(() => done())
          .catch(done);
      });
    });

    describe('pass an async callback to be called from C++', () => {
      it('nominal', (done) => {
        dll.GiveMeFiveAsync(async (pass, name) => {
          assert.strictEqual(pass, 420);
          assert.isString(name);
          return new Promise((res) => setTimeout(() => res('sent from JS ' + name), 10));
        }).then((r) => {
          assert.isString(r);
          assert.strictEqual(r, 'received from JS: sent from JS with cheese');
          done();
        }).catch(done);
      });

      it('exception cases', (done) => {
        dll.GiveMeFiveAsync(async () => {
          return Promise.reject('420 failed');
        })
          .catch((e) => {
            assert.match(e.message, /420 failed/);
          })
          .then(() => dll.GiveMeFiveAsync(() => Promise.resolve(Infinity)))
          .catch((e) => {
            assert.match(e.message, /callback return value of type 'std::string'/);
          })
          .then(() => done())
          .catch(done);
      });
    });
  });
});
