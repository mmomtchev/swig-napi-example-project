import WASM from '../lib/wasm.mjs';
import syncTests from './sync.js';

// This test can be run either in Node.js or in the browser
// npx run test:nodejs
// npx run test:browser

describe('WASM', () => {
  syncTests(WASM);
});
