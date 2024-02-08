/**
 * Karma for the main browser unit tests set
 */

module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['mocha'],
    client: {
      mocha: {
        reporter: 'html',
        timeout: 40000
      },
      args: process.env.NO_ASYNC ? ['no-async'] : []
    },
    files: [
      { pattern: 'build/bundle-mocha.js', included: true },
      { pattern: 'build/*', served: true, included: false }
    ],
    customHeaders: process.env.NO_ASYNC ? [] : [
      { name: 'Cross-Origin-Opener-Policy', value: 'same-origin' },
      { name: 'Cross-Origin-Embedder-Policy', value: 'require-corp' }
    ],
    exclude: [
    ],
    preprocessors: {
    },
    reporters: ['verbose'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    browsers: ['Chrome'],
    singleRun: true,
    concurrency: Infinity
  });
};
