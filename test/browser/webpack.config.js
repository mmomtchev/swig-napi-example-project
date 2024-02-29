import * as path from 'node:path';
import * as process from 'node:process';
import { fileURLToPath } from 'node:url';

// This contains two different builds: the standalone webpage and the mocha bundle

export default [
  /**
   * Bundle for a standalone webpage
   * 
   * This is the configuration you need to create a webpage
   */
  {
    entry: './index.js',
    output: {
      filename: 'bundle.js',
      path: path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'build')
    },
    /**
     * WARNING: Important!
     * 
     * The default js wrapper (example.js) generated by emscripten - the one that loads
     * the WASM binary - works in every environment. It does so by detecting if it
     * runs in Node.js or in a browser - so that it can know where to load the WASM
     * binary from.
     * 
     * This autodetection makes it reference Node.js-specific extensions that do not
     * exist in a browser which confuses webpack. The following section tells webpack
     * to not expand those statements - we know that these sections won't be executed in
     * the browser since they are dependant on the environment auto-detection.
     * 
     * The list is current for emscripten 3.1.51. Later versions may additional
     * symbols.
     * 
     * Alternatively, if you want to publish a WASM that works without any custom
     * webpack configuration, you can take a look at magickwand.js - magickwand.js
     * explicitly disables the Node.js environment from its WASM binary.
     * 
     * Node.js is best served by the native build anyway.
     * 
     * The emscripten option that does this is:
     *   '-sENVIRONMENT=web,webview,worker'
     */
    externals: {
      'fs': 'fs',
      'worker_threads': 'worker_threads',
      'module': 'module',
      'vm': 'vm',
      './': '"./"'
    },
    ignoreWarnings: [
      // These have to be fixed in emscripten
      // https://github.com/emscripten-core/emscripten/issues/20503
      {
        module: /example\.worker\.js$/,
        message: /dependency is an expression/,
      },
      {
        message: /Circular dependency/
      },
      {
        module: /example\.worker\.js$/,
        message: /dependencies cannot be statically extracted/
      }
    ],
    devServer: {
      port: 8030,
      static: {
        directory: path.dirname(fileURLToPath(import.meta.url))
      },
      devMiddleware: {
        'publicPath': '/build'
      },
      headers: process.env.NO_ASYNC ? {} : {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp'
      }
    }
  },

  /**
   * Bundle for mocha
   * 
   * This is the configuration you need to create unit tests
   */
  {
    entry: './run-mocha.js',
    output: {
      filename: 'bundle-mocha.js',
      path: path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'build')
    },
    ignoreWarnings: [
      {
        module: /example\.worker\.js$/,
        message: /dependency is an expression/,
      },
      {
        message: /Circular dependency/
      },
      {
        module: /example\.worker\.js$/,
        message: /dependencies cannot be statically extracted/
      },
      {
        module: /example\.worker\.js$/,
        message: /dependencies cannot be statically extracted/
      },
      // yes, the mocha bundle is too big for the web
      {
        message: /exceed the recommended size limit/
      },
      {
        message: /exceeds the recommended limit/
      }
    ],
    externals: {
      'fs': 'fs',
      'worker_threads': 'worker_threads',
      'module': 'module',
      'vm': 'vm',
      './': '"./"'
    }
  }
];
