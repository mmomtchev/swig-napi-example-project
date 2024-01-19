import WASM from '../lib/wasm.mjs';
import { assert } from 'chai';

describe('WASM', () => {
  let bindings: Awaited<typeof WASM>;

  before('load WASM', (done) => {
    WASM.then((_bindings) => {
      bindings = _bindings;
      done();
    });
  });

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

    it('retrieve a ReturnVector', () => {
      const r = bindings.ReturnVector();
      assert.isArray(r);
      assert.lengthOf(r, 3);
      assert.strictEqual(r[0].get(), 1);
    });
  });

});
