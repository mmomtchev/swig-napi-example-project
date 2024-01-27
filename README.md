# SWIG Node-API example skeleton

This is an example skeleton for a C++ project that uses SWIG Node-API with a dual-build system supporting both Node.js/native and Browser/WASM builds

If you want to see a real-world complex project that uses `conan` to manage its dependencies, you should take a look at [`magickwand.js`](https://github.com/mmomtchev/magickwand.js) - the ImageMagick-7 bindings for JavaScript.

# Try it for yourself

**While the compiled native and WASM modules should work on all OS supported by `node-gyp`, generating the SWIG wrappers and building the WASM is supported only on Linux (although you may find that it works most of the time on other OS)**

The Github Actions automated build & test CI is set up to work on all three major OS.

After installing **SWIG JavaScript Evolution** which must be available in your path:

```shell
git clone https://github.com/mmomtchev/swig-napi-example-project.git
cd swig-napi-example-project
npm install
npm run swig
```

Build the Node.js native addon version:
```
npx node-gyp configure
npx node-gyp build
```

Build the browser-compatible WASM version (must have `emsdk` in your `PATH`):
```
CC=emcc CXX=em++ npx node-gyp configure --target_platform=emscripten 
CC=emcc CXX=em++ npx node-gyp build
```

Run the unit tests:
```
# Run everything
npm test

# Run only Node.js
npm run test:nodejs

# Run only the browser
npm run test:browser
```

# CJS, MJS, ES6, TypeScript...

You should be aware that publishing an `npm` module that works in every possible environment - including the browser, Node.js, being `import`ed, being `require`d, being transpiled from TypeScript, being bundled by `webpack`, etc... - is a daunting task that requires very good understanding of the various module loaders. Every effort has been made for this package to be as universal as possible - including a trick with a dummy `package.json` in the `build` directory - so that it can serve as a good starting point for your own package. Also do not forget to check [`magickwand.js`](https://github.com/mmomtchev/magickwand.js) for a real-world package that works both in Node.js and in the browser.

