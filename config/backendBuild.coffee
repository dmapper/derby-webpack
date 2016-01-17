_ = require 'lodash'
webpack = require 'webpack'
BackendConfig = require './backend'

module.exports = class BackendBuildConfig extends BackendConfig

  constructor: ->
    super

    @config.cache = false
    @config.debug = false
    @config.devtool = 'source-map'

    @config.plugins = @config.plugins.concat [
      new webpack.optimize.UglifyJsPlugin({
        compress:
          warnings: false
      })
    ]