# SWIG Node-API example skeleton

**Update: since Oct 24 I am homeless and living in my van. I lost access to most of my computer hardware. The eviction from my home has been timed for maximum effect as I was not present when it happened. I have only a single set of clothes and no means to get anything else. Please, if you use my software, consider asking everyone around you if they are taking part in this extortion and why.**

[![CI](https://github.com/mmomtchev/swig-napi-example-project/actions/workflows/run.yml/badge.svg)](https://github.com/mmomtchev/swig-napi-example-project/actions/workflows/run.yml)
[![codecov](https://codecov.io/gh/mmomtchev/swig-napi-example-project/graph/badge.svg?token=05LMSUTBVA)](https://codecov.io/gh/mmomtchev/swig-napi-example-project)

This is an example skeleton for a C++ project that uses SWIG Node-API with a dual-build system supporting both Node.js/native and Browser/WASM builds using the traditional `node-gyp` build system.

It includes some non-trivial examples such as C buffers, vectors of objects and maps.

[SWIG Node-API example skeleton using `hadron`](https://github.com/mmomtchev/hadron-swig-napi-example-project.git) contains a similar template using the new [`meson`-based `hadron`](https://github.com/mmomtchev/hadron) build system which is less mature but offers numerous advantages.

If you want to see a real-world complex project that uses `conan` to manage its dependencies, you should take a look at [`magickwand.js`](https://github.com/mmomtchev/magickwand.js) - the ImageMagick-7 bindings for JavaScript:
 * versions before 1.0 use `node-gyp` and support only Node.js native
 * versions 1.x use `node-gyp` and `conan` and support both Node.js native and WASM, this is a very hackish build system that should be avoided
 * versions starting from 2.0 use the new `hadron` build

# Try building yourself

## SWIG JSE

You must install **SWIG JavaScript Evolution** which must be available in your path.

A fast and easy way to get a binary for your platform is `conan`:

```shell
conan remote add swig-jse https://swig.momtchev.com/artifactory/api/conan/swig-jse
conan install --tool-requires swig-jse/5.0.3 --build=missing
```

If you want to use it outside of `conan`, you can find the directory where it is installed:

```shell
conan list swig-jse/5.0.3:*
conan cache path swig-jse/5.0.3:28c51be622f275401498fce89a192712bae70ae0
```

Be aware that most of the time, SWIG is developed, tested and used on Linux.

Real-world projects usually carry pregenerated SWIG wrappers and do not regenerate these at each installation.

Another, riskier, option is to pull `swig-jse` on the user's machine from `conan`.

There is also a Github Action: https://github.com/marketplace/actions/setup-swig

## Build the project

```shell
git clone https://github.com/mmomtchev/swig-napi-example-project.git
cd swig-napi-example-project
npm install
npm run swig
```

Build the Node.js native addon version:
```shell
npx node-gyp configure
npx node-gyp build
```

Build the browser-compatible WASM version (must have `emsdk` in your `PATH`):
```shell
CC=emcc CXX=em++ npx node-gyp configure --target_platform=emscripten 
CC=emcc CXX=em++ npx node-gyp build
```

Run the unit tests:
```shell
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

# Code instrumentation

## Native

If you need to debug your code, the best debug target is the Node.js native build on Linux.

The Node.js native version supports full code instrumentation - debug builds, running with [`asan`](https://github.com/google/sanitizers/wiki/AddressSanitizer) enabled and dual-language code coverage with `gcov` and `lcov` on the C++ side (*only on Linux & macOS*) and `c8` on the JavaScript side. The [CI scripts](https://github.com/mmomtchev/swig-napi-example-project/blob/main/.github/workflows/run.yml) can be used as example for setting these up. The automated `asan` build includes a list of the known leaks in the Node.js/V8 bootstrapping code - note that this is a fast moving target - that is current for Node.js 18.19.1.

[launch.json](https://github.com/mmomtchev/swig-napi-example-project/blob/main/.vscode/launch.json) has an example debug configuration for Visual Studio Code on Linux. Build with:

```shell
npm run swig:debug
node-gyp configure build --debug
```

## WASM

The WASM build also supports source-level debugging, but at the moment this is supported only with the built-in debugger in Chrome. As far as I know, it is currently not possible to make webpack pack the C/C++ source files automatically, you will have to copy these to the `test/browser/build` directory. You will also have to copy `build/Debug/example.wasm.map` and to change `lib/wasm.mjs` to point to the debug build. Use the following commands to build:

```shell
npm run swig:debug
CC=emcc CXX=em++ npx node-gyp configure build --target_platform=emscripten --debug
```

Then, it should be possible to step into the WASM code, showing the C/C++ source files instead of the WASM disassembly.

Also be sure to read https://developer.chrome.com/docs/devtools/wasm/.
