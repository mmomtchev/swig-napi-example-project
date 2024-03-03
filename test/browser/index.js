// This is the index.js of the web page demo

import WASM from '../../lib/wasm.mjs';

console.log('Hello from WASM');

WASM.then((bindings) => {
  console.log('WASM loaded and compiled', bindings);
  const Blob = bindings.Blob;
  
  const blob = new Blob(1024);
  if (!(blob instanceof Blob)) throw new Error('Failed creating a blob');
  console.log('Created a Blob!');

  blob.Fill(17);
  const ab = blob.Export();
  if (ab.byteLength !== 1024) throw new Error('Length does not match');
  console.log('got', ab);
  const view = new Uint8Array(ab);
  if (view[17] !== 17) throw new Error('Data does not match');

  document.getElementsByTagName('body')[0].innerHTML = 'Successfully loaded WASM and created a blob';
});
