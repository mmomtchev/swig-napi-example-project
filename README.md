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

# WASM without COOP/COEP

Currently, WASM projects that use asynchronous wrappers require that [`COOP`/`COEP`](https://web.dev/articles/coop-coep) is enabled. In this example it is enabled by the `webpack` built-in server and by the `karma` test runner. Users of your module will have to host it on web servers that support and send these headers - **it is a requirement on the web server end - ie a configuration option that must be enabled in Apache or nginx**. For example, currently Github Pages and many low-end hosting providers do not support it.

Alternatively, this example can be built without asynchronous wrappers in order to produce a WASM binary that does not require `COOP`/`COEP`. The only real difference is the `emscripten` build configuration which can be found in `emscripten.gypi`.

In this case, there are two possible strategies:
 * Accept that calling C++ functions will produce main thread latency - which works well if all your C++ methods run very fast
 * Use [`GoogleCromeLabs/comlink`](https://github.com/GoogleChromeLabs/comlink) to call them in a worker thread - which works well if all your C++ methods have very long execution times because it adds significant overhead when calling them (*this will require a custom serializer for C++ object - I plan to make an example*)

Mixing the two is possible, but C++ functions running in the main thread and C++ functions running the in `comlink` worker won't be able to share objects as they will be running in separate memory spaces.
