import WASM from '../lib/wasm.mjs';
import { assert } from 'chai';

// This test can be run either in Node.js or in the browser
// npx run test:nodejs
// npx run test:browser

const no_async = !!(
  (typeof process !== 'undefined' && process.env.NO_ASYNC) ||
  (typeof __karma__ !== 'undefined' && __karma__.config.args.includes('no-async'))
);

describe('WASM', () => {
  let Blob;
  let asyncEnabled;
  let GiveMeFiveAsync;
  before('load WASM', (done) => {
    WASM.then((bindings) => {
      Blob = bindings.Blob;
      asyncEnabled = bindings.asyncEnabled;
      GiveMeFiveAsync = bindings.GiveMeFiveAsync;
      done();
    });
  });

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
        GiveMeFiveAsync((pass, name) => {
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
        GiveMeFiveAsync(() => {
          throw new Error('420 failed');
        })
          .catch((e) => {
            assert.match(e.message, /420 failed/);
          })
          .then(() => GiveMeFiveAsync(() => Infinity))
          .catch((e) => {
            assert.match(e.message, /callback return value of type 'std::string'/);
          })
          .then(() => done())
          .catch(done);
      });
    });

    describe('pass an async callback to be called from C++', () => {
      it('nominal', (done) => {
        GiveMeFiveAsync(async (pass, name) => {
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
        GiveMeFiveAsync(async () => {
          return Promise.reject('420 failed');
        })
          .catch((e) => {
            assert.match(e.message, /420 failed/);
          })
          .then(() => GiveMeFiveAsync(() => Promise.resolve(Infinity)))
          .catch((e) => {
            assert.match(e.message, /callback return value of type 'std::string'/);
          })
          .then(() => done())
          .catch(done);
      });
    });

  });
});
