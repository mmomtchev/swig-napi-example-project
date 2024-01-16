# SWIG Node-API example skeleton

This is an example skeleton for a C++ project that uses SWIG Node-API with a dual-build system supporting both Node.js/native and Browser/WASM builds

If you want to see a real-world complex project that uses `conan` to manage its dependencies, you should take a look at [`magickwand.js`](https://github.com/mmomtchev/magickwand.js) - the ImageMagick-7 bindings for JavaScript.

# Try it for yourself

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
npm test
```

**At the moment only Linux is supported**
