{
  'variables': {
    'target_platform%': 'default',
    'enable_coverage%': 'false',
    'enable_asan%': 'false'
  },
  'conditions': [
    # All the magic options necessary for a WASM build
    ['target_platform == "emscripten"', {
      'includes': [
        'emscripten.gypi',
      ]
    }]
  ],
  'target_defaults': {
    'include_dirs': [
      # This must always come first and cannot be conditional
      '<!@(node -p "require(\'emnapi\').include")'
    ],
    'dependencies': [
      # Very careful here - this enables compiler options that modify the ABI
      # Especially with MSVC _everything_ you link with must be compiled with
      # these options
      '<!@(node -p "require(\'node-addon-api\').targets"):node_addon_api_except'
    ],
    'conditions': [
      # code coverage build
      ["enable_coverage == 'true'", {
        "cflags_cc": [ "-fprofile-arcs", "-ftest-coverage" ],
        "ldflags" : [ "-lgcov", "--coverage" ]
      }],
      # ASAN build
      ["enable_asan == 'true'", {
        "cflags_cc": [ "-fsanitize=address" ],
        "ldflags" : [ "-fsanitize=address" ]
      }],
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
  'targets': [
    {
      # The main binary target - both native or WASM
      'target_name': 'example',
      'include_dirs': [
        '<(module_root_dir)/src'
      ],
      'includes': [
        # Disables some SWIG-specific warnings
        'swig.gypi'
      ],
      'sources': [
        # These are the examples that are wrapped
        'src/blob.cc',
        'src/array.cc',
        'src/map.cc',
        'src/callback.cc',
        # These are the SWIG wrappers
        'build/example_wrap.cc'
      ]
    }
  ]
}
