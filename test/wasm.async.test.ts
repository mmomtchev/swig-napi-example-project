import WASM from '../lib/wasm.mjs';
import asyncTests from './async.js';

// This test can be run either in Node.js or in the browser
// npx run test:nodejs
// npx run test:browser

const no_async = !!(
  (typeof process !== 'undefined' && process.env.NO_ASYNC) ||
  // @ts-ignore
  (typeof __karma__ !== 'undefined' && __karma__.config.args.includes('no-async'))
);

describe('WASM', () => {
  asyncTests(WASM, no_async);
});
