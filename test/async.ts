import { assert } from 'chai';
import type Bindings from '..';

// These are all the asynchronous tests
// They are shared between the Node.js native version and the WASM version
// (the only difference being that WASM must be loaded by resolving its Promise)

export default function (dll: (typeof Bindings) | Promise<typeof Bindings>, no_async: boolean) {
  let bindings: typeof Bindings;
  if (dll instanceof Promise) {
    before('load WASM', (done) => {
      dll.then((loaded) => {
        bindings = loaded;
        done();
      });
    });
  } else {
    bindings = dll;
  }

  it(`async is ${no_async ? 'disabled' : 'enabled'}`, () => {
    assert.strictEqual(bindings.asyncEnabled, !no_async);
  });

  describe('async', () => {
    if (no_async) return;

    it('write into an existing ArrayBuffer', (done) => {
      const blob = new bindings.Blob(10);
      const ab = new ArrayBuffer(10);
      blob.Fill(42);
      blob.WriteAsync(ab).then(() => {
        const view = new Uint8Array(ab);
        view.forEach((v) => assert.strictEqual(v, 42));
        done();
      }).catch(done);
    });

    it('try funny things', (done) => {
      const blob = new bindings.Blob(12);
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
        bindings.GiveMeFiveAsync(function(pass, name) {
          assert.strictEqual(pass, 420);
          assert.isString(name);
          assert.strictEqual(this, globalThis);
          return 'sent from JS ' + name;
        }).then((r) => {
          assert.isString(r);
          assert.strictEqual(r, 'received from JS: sent from JS with cheese');
          done();
        }).catch(done);
      });

      it('C-style', (done) => {
        bindings.GiveMeFive_C_Async((pass, name) => {
          assert.strictEqual(pass, 420);
          assert.isString(name);
          return 'sent from JS ' + name;
        }).then((r) => {
          assert.isString(r);
          assert.strictEqual(r, 'received from JS: sent from JS with extra cheese');
          done();
        }).catch(done);
      });

      it('void () special case', (done) => {
        let didCall = false;
        bindings.JustCallAsync(function() {
          assert.strictEqual(this, globalThis);
          didCall = true;
        }).then(() => {
          assert.strictEqual(didCall, true);
          done();
        }).catch(done);
      });

      it('exception cases', (done) => {
        bindings.GiveMeFiveAsync(() => {
          throw new Error('420 failed');
        })
          .catch((e) => {
            assert.match(e.message, /420 failed/);
          })
          .then(() => bindings.GiveMeFiveAsync(() => Infinity as unknown as string))
          .catch((e) => {
            assert.match(e.message, /callback return value of type 'std::string'/);
          })
          .then(() => done())
          .catch(done);
      });
    });

    describe('pass an async callback to be called from C++', () => {
      it('nominal', (done) => {
        bindings.GiveMeFiveAsync(async (pass, name) => {
          assert.strictEqual(pass, 420);
          assert.isString(name);
          return new Promise<string>((res) => setTimeout(() => res('sent from JS ' + name), 10));
        }).then((r) => {
          assert.isString(r);
          assert.strictEqual(r, 'received from JS: sent from JS with cheese');
          done();
        }).catch(done);
      });

      it('exception cases', (done) => {
        bindings.GiveMeFiveAsync(async () => {
          return Promise.reject('420 failed') as Promise<string>;
        })
          .catch((e) => {
            assert.match(e.message, /420 failed/);
          })
          .then(() => bindings.GiveMeFiveAsync(() => Promise.resolve(Infinity as unknown as string)))
          .catch((e) => {
            assert.match(e.message, /callback return value of type 'std::string'/);
          })
          .then(() => done())
          .catch(done);
      });
    });
  });
}
