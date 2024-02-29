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
# Run all unit tests
npm test

# Run only the Node.js unit tests
npm run test:nodejs

# Run only the browser unit tests
npm run test:browser

# Serve the webpack project in a browser
# (open http://localhost:8030/)
npm run start
```

# CJS, MJS, ES6, TypeScript...

This project is setup to provide a modern JavaScript environment - it uses `type: module`, JavaScript files are treated as ES6 by default and the TypeScript is also transpiled to ES6. This setup is what most newly published `npm` modules use in 2024. Such package will be compatible with all modern bundlers and recent Node.js versions when using `import` declarations. It won't be compatible with being `require`d from CJS code.

You can check [`magickwand.js`](https://github.com/mmomtchev/magickwand.js) for an example of a real-world SWIG-generated dual-build (WASM/native) project that is compatible with both ES6 and CJS. However you should be aware that supporting both ES6 and CJS adds substantial complexity to the packaging of a module. It is recommended that all new JavaScript and TypeScript projects use ES6 as their main targets.

# WASM without COOP/COEP

Currently, WASM projects using asynchronous wrappers require that [`COOP`/`COEP`](https://web.dev/articles/coop-coep) is enabled. In this example, it is enabled by the `webpack` built-in server and by the `karma` test runner. Users of your module will have to host it on web servers that support and send these headers - **this is a requirement on the web server end - ie a configuration option that must be enabled in Apache or nginx**. For example, currently Github Pages and many low-end hosting providers do not support it.

Alternatively, this example can be built without asynchronous wrappers in order to produce a WASM binary that does not require `COOP`/`COEP`. The only real difference is the `emscripten` build configuration which can be found in `emscripten.gypi`.

In this case, there are two possible strategies:
 * Accept that calling C++ functions will produce main thread latency - which works well if all your C++ methods run very fast
 * Use [`GoogleCromeLabs/comlink`](https://github.com/GoogleChromeLabs/comlink) to call them in a worker thread - which works well if all your C++ methods have very long execution times because it adds significant overhead when calling them (*this will require a custom serializer for C++ object - I plan to make an example*)

Mixing the two is possible, but C++ functions running in the main thread and C++ functions running the in `comlink` worker won't be able to share objects as they will be running in separate memory spaces.

# Code instrumentation

## Native

If you need to debug your code, the best debug target is the Node.js native build on Linux.

The Node.js native version supports full code instrumentation - debug builds, running with [`asan`](https://github.com/google/sanitizers/wiki/AddressSanitizer) enabled and dual-language code coverage with `gcov` and `lcov` on the C++ side (*only on Linux & macOS*) and `c8` on the JavaScript side. The [CI scripts](https://github.com/mmomtchev/swig-napi-example-project/blob/main/.github/workflows/run.yml) can be used as example for setting these up. The automated `asan` build includes a list of the known leaks in the Node.js/V8 bootstrapping code - note that this is a fast moving target - that is current for Node.js 18.19.1.

[launch.json](https://github.com/mmomtchev/swig-napi-example-project/blob/main/.vscode/launch.json) has an example debug configuration for Visual Studio Code on Linux. Build with:

```
npm run swig:debug
node-gyp configure build --debug
```

## WASM

The WASM build also supports source-level debugging, but at the moment this is supported only with the built-in debugger in Chrome. As far as I know, it is currently not possible to make webpack pack the C/C++ source files automatically, you will have to copy these to the `test/browser/build` directory. You will also have to copy `build/Debug/example.wasm.map` and to change `lib/wasm.mjs` to point to the debug build. Use the following commands to build:

```
npm run swig:debug
CC=emcc CXX=em++ npx node-gyp configure build --target_platform=emscripten --debug
```

Then, it should be possible to step into the WASM code, showing the C/C++ source files instead of the WASM disassembly.
