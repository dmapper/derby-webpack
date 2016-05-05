var BackendBuildConfig = require('../config/backendBuild');

module.exports = function(opts) {
  var options = {};
  try {
    require.resolve(process.cwd() + '/derby-webpack.config');
    options = require(process.cwd() + '/derby-webpack.config');
  } catch (e) {}
  options.backend || (options.backend = {});
  options.backend.cache = true;
  options.backend.uglify = false;
  return (new BackendBuildConfig(options)).config;
};