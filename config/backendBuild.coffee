defaultsDeep = require 'lodash/defaultsDeep'
webpack = require 'webpack'
BackendConfig = require './backend'

module.exports = class BackendBuildConfig extends BackendConfig

  constructor: ->
    super
    defaultsDeep @options,
      backend:
        cache: false
        uglify: true

    @config.cache = @options.backend.cache
    @config.debug = false
    @config.devtool = 'source-map'

    if @options.backend.uglify
      @config.plugins.push new webpack.optimize.UglifyJsPlugin({
        compress:
          warnings: false
      })