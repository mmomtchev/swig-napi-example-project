# Based on https://github.com/toyobayashi/emnapi-node-gyp-test/blob/main/wasm/common.gypi
{
  'variables': {
    'OS': 'emscripten',
    'clang': 1,
    'target_arch%': 'wasm32',
    'target_platform%': 'emscripten',
    'wasm_threads%': 0,
    'product_extension%': 'mjs',
    'emscripten_pthread': [
      # Emscripten + emnapi libuv multithreading
      '-pthread',
      '-DEMNAPI_WORKER_POOL_SIZE=4'
    ]
  },
  'target_defaults': {
    'type': 'executable',
    'product_extension': '<(product_extension)',
    'cflags': [
      '-Wall',
      '-Wextra',
      '-Wno-unused-parameter',
      '-Wno-sometimes-uninitialized',
      '-sNO_DISABLE_EXCEPTION_CATCHING',
      '<@(emscripten_pthread)'
    ],
    'ldflags': [
      '--js-library=<!(node -p "require(\'emnapi\').js_library")',
      '-sALLOW_MEMORY_GROWTH=1',
      '-sEXPORTED_FUNCTIONS=["_napi_register_wasm_v1","_malloc","_free"]',
      '-sNO_DISABLE_EXCEPTION_CATCHING',
      '--bind',
      '-sMODULARIZE',
      '-sEXPORT_ES6=1',
      '-sEXPORT_NAME=example',
      # Pay attention to this value, if you overflow it, you will get
      # all kinds of weird errors
      '-sSTACK_SIZE=1MB',
      '<@(emscripten_pthread)',
      '-sDEFAULT_PTHREAD_STACK_SIZE=1MB',
      '-sPTHREAD_POOL_SIZE=4',
      '-Wno-pthreads-mem-growth'
    ],
    'defines': [
      '__STDC_FORMAT_MACROS',
    ],
    'sources': [
      '<!@(node -p "require(\'emnapi\').sources.map(x => JSON.stringify(path.relative(process.cwd(), x))).join(\' \')")'
    ],
    'default_configuration': 'Release',
    'configurations': {
      'Debug': {
        'ldflags': [ '-sSAFE_HEAP=1', '-gsource-map', '-sASSERTIONS=2', '-sSTACK_OVERFLOW_CHECK=2' ],
      }
    },
    'conditions': [
      ['target_arch == "wasm64"', {
        'cflags': [
          '-sMEMORY64=1',
        ],
        'ldflags': [
          '-sMEMORY64=1'
        ]
      }],
      ['wasm_threads == 1', {
        'cflags': [ '-pthread' ],
        'ldflags': [ '-pthread' ],
      }]
    ]
  }
}
