import WASM from '../../lib/wasm.mjs';

console.log('Hello from WASM');

WASM.then((bindings) => {
  console.log('WASM loaded and compiled');
  Blob = bindings.Blob;
  
  const blob = new Blob(1024);
  if (!(blob instanceof Blob)) throw new Error('Failed creating a blob');
  console.log('Created a Blob!');

  document.getElementsByTagName('body')[0].innerHTML = 'Successfully loaded WASM and created a blob';
});
