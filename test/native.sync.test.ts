import bindings from '../lib/native.cjs';
import syncTests from './sync.js';

// This test is exclusive to Node.js
// npx run test:nodejs

describe('native', () => {
  syncTests(bindings);
});
