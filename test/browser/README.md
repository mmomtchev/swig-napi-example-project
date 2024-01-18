# Browser (webpack) example

This directory contains a small webpack project that calls the WASM binary.


It can be used:


  * either from `karma`, which starts the browser and loads a `mocha` environment in it to run the unit tests

    *(run in this directory)*

    `npx webpack --mode=production`

    `npx karma start ./karma.conf.cjs`


  * either as a standalone webpage to be locally visited with a browser:

    *(run in this directory)*

    `npx webpack serve --mode=production`

    then open `http://localhost:8030/` in a browser
