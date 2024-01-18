import WASM from '../lib/wasm.mjs';
import { assert } from 'chai';

// This test can be run either in Node.js or in the browser
// npx run test:nodejs
// npx run test:browser

describe('WASM', () => {
  let Blob;
  before('load WASM', (done) => {
    WASM.then((bindings) => {
      Blob = bindings.Blob;
      done();
    });
  });

  describe('sync', () => {
    it('create a new null Blob', () => {
      const blob = new Blob;
      const ab = blob.Export();
      assert.instanceOf(ab, ArrayBuffer);
      assert.strictEqual(ab.byteLength, 0);
    });

    it('create a new empty Blob', () => {
      const blob = new Blob(10);
      const ab = blob.Export();
      assert.instanceOf(ab, ArrayBuffer);
      assert.strictEqual(ab.byteLength, 10);
    });

    it('fill a new Blob', () => {
      const blob = new Blob(10);
      blob.Fill(17);
      const ab = blob.Export();
      assert.instanceOf(ab, ArrayBuffer);
      assert.strictEqual(ab.byteLength, 10);
      const view = new Uint8Array(ab);
      view.forEach((v) => assert.strictEqual(v, 17));
    });

    it('write into an existing ArrayBuffer', () => {
      const blob = new Blob(10);
      const ab = new ArrayBuffer(10);
      blob.Fill(42);
      blob.Write(ab);
      const view = new Uint8Array(ab);
      view.forEach((v) => assert.strictEqual(v, 42));
    });

    it('try funny things', () => {
      const blob = new Blob(12);
      const ab = new ArrayBuffer(8);
      assert.throws(() => {
        blob.Write(ab);
      }, /Sizes must match/);
    });

  });

});
