{
  'variables': {
    'target_platform%': 'default'
  },
  'conditions': [
    ['target_platform == "emscripten"', {
      'includes': [
        'emscripten.gypi',
      ]
    }]
  ],
  'includes': [
    'swig.gypi'
  ],
  'target_defaults': {
    'includes': [
      'except.gypi'
    ],
    'include_dirs': [
      # This must always come first and cannot be conditional
      '<!@(node -p "require(\'emnapi\').include")',
      '<!@(node -p "require(\'node-addon-api\').include")',
    ],
    'configurations': {
      'Debug': {
        'defines': [ 'DEBUG', '_DEBUG' ],
        'cflags': [ '-g', '-O0',  ],
      },
      'Release': {
        'defines': [ 'NDEBUG' ],
        'defines!:': [ 'DEBUG' ],
        'cflags': [ '-O3' ],
        'ldflags': [ '-O3' ],
      }
    }
  },
  'includes': [
    'swig.gypi'
  ],
  'targets': [
    {
      # The main binary target - both native or WASM
      'target_name': 'example',
      'include_dirs': [
        '<(module_root_dir)/src'
      ],
      'sources': [
        'src/blob.cc',
        'src/array.cc',
        'build/example_wrap.cc'
      ]
    }
  ]
}
