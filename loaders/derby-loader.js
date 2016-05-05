var loaderUtils = require("loader-utils");

module.exports = function(source, map) {
  this.cacheable();

  // Proprocess app.component(require('./tratata')) call.
  source = source.replace(/(app.component\(\s*require\(\s*['"])([^'"]*)(['"]\s*\)\s*)/g,
      '$1' + JSON.parse(loaderUtils.stringifyRequest(this, require.resolve('./derby-component-loader'))) +  '!$2$3');

  return this.callback(null, source, map);
};
