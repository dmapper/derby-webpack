var BackendBuildConfig = require('./config/backendBuild');
var BackendWatchConfig = require('./config/backendWatch');
var FrontendBuildConfig = require('./config/frontendBuild');
var FrontendWatchConfig = require('./config/frontendWatch');

module.exports = (function() {
  var options = {};
  try {
    require.resolve(process.cwd() + '/derby-webpack.config');
    options = require(process.cwd() + '/derby-webpack.config');
  } catch (e) {}
  if (process.env.WP_BACKEND) {
    if (process.env.WP_WATCH) {
      return (new BackendWatchConfig(options)).config;
    } else {
      return (new BackendBuildConfig(options)).config;
    }
  } else {
    if (process.env.WP_WATCH) {
      return (new FrontendWatchConfig(options)).config;
    } else {
      return (new FrontendBuildConfig(options)).config;
    }
  }
})();
