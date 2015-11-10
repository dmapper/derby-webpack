var loaderUtils = require("loader-utils");

module.exports = function(source) {
  this.cacheable();

  // Proprocess app.component(require('./tratata')) call.
  source = source.replace(/(app.component\(\s*require\(\s*['"])([^'"]*)(['"]\s*\)\s*)/g,
      '$1' + loaderUtils.stringifyRequest(this, require.resolve('./derby-component-loader')) +  '!$2$3');

  return source;
};
