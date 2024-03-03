import { assert } from 'chai';
import type Bindings from '..';

// These are all the synchronous tests
// They are shared between the Node.js native version and the WASM version
// (the only difference being that WASM must be loaded by resolving its Promise)

export default function (dll: (typeof Bindings) | Promise<typeof Bindings>) {
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

  describe('sync', () => {
    it('create a new null Blob', () => {
      const blob = new bindings.Blob;
      const ab = blob.Export();
      assert.instanceOf(ab, ArrayBuffer);
      assert.strictEqual(ab.byteLength, 0);
    });

    it('create a new empty Blob', () => {
      const blob = new bindings.Blob(10);
      const ab = blob.Export();
      assert.instanceOf(ab, ArrayBuffer);
      assert.strictEqual(ab.byteLength, 10);
    });

    it('fill a new Blob', () => {
      const blob = new bindings.Blob(10);
      blob.Fill(17);
      const ab = blob.Export();
      assert.instanceOf(ab, ArrayBuffer);
      assert.strictEqual(ab.byteLength, 10);
      const view = new Uint8Array(ab);
      view.forEach((v) => assert.strictEqual(v, 17));
    });

    it('write into an existing ArrayBuffer', () => {
      const blob = new bindings.Blob(10);
      const ab = new ArrayBuffer(10);
      blob.Fill(42);
      blob.Write(ab);
      const view = new Uint8Array(ab);
      view.forEach((v) => assert.strictEqual(v, 42));
    });

    it('try funny things', () => {
      const blob = new bindings.Blob(12);
      const ab = new ArrayBuffer(8);
      assert.throws(() => {
        blob.Write(ab);
      }, /Sizes must match/);
    });

    it('pass a ReadOnlyVector', () => {
      const obj1 = new bindings.IntObject(1);
      const obj2 = new bindings.IntObject(2);
      const obj3 = new bindings.IntObject(3);
      const r = bindings.ReadOnlyVector([obj1, obj2, obj3]);
      assert.strictEqual(r, 1);
    });

    it('retrieve a ReturnVector 1', () => {
      const r = bindings.ReturnVector1();
      assert.isArray(r);
      assert.lengthOf(r, 3);
      assert.strictEqual(r[0].get(), 1);
    });

    it('retrieve a ReturnVector 2', () => {
      const r = bindings.ReturnVector2();
      assert.isArray(r);
      assert.lengthOf(r, 3);
      assert.strictEqual(r[0].get(), 1);
    });

    it('pass an object as a map', () => {
      bindings.PutMap({ expected: 'value' });
    });

    it('retrieve a map as an object', () => {
      const r = bindings.GetMap();
      assert.isObject(r);
      assert.propertyVal(r, 'returned', 'value');
    });

    describe('pass a callback to be called from C++', () => {
      it('nominal', () => {
        const r = bindings.GiveMeFive((pass, name) => {
          assert.strictEqual(pass, 420);
          assert.isString(name);
          return 'sent from JS ' + name;
        });
        assert.isString(r);
        assert.strictEqual(r, 'received from JS: sent from JS with cheese');
      });

      it('C-style', () => {
        const r = bindings.GiveMeFive_C((pass, name) => {
          assert.strictEqual(pass, 420);
          assert.isString(name);
          return 'sent from JS ' + name;
        });
        assert.isString(r);
        assert.strictEqual(r, 'received from JS: sent from JS with extra cheese');
      });

      it('exception cases', () => {
        assert.throws(() => {
          bindings.GiveMeFive(() => {
            throw new Error('420 failed');
          });
        }, /420 failed/);

        assert.throws(() => {
          bindings.GiveMeFive(() => Infinity as unknown as string);
        }, /callback return value of type 'std::string'/);
      });
    });
  });
}
