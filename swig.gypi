{
  'cflags_cc': [
    '-Wno-deprecated-declarations',
    '-Wno-unused-function',
    '-Wno-type-limits',
    '-Wno-deprecated-copy'
  ],
  'xcode_settings': {
    'OTHER_CFLAGS': [
      '-Wno-sometimes-uninitialized',
    ]
  },
  'msvs_settings': {
    'VCCLCompilerTool': {
      # PREfast requires too much memory for Github Actions
      'EnablePREfast': 'false',
      'AdditionalOptions': [
        # SWIG Node-API uses deliberate shadowing inside inner scopes
        '/wo6246',
        '/wo28182'
      ]
    }
  }
}
