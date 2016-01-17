_ = require 'lodash'
webpack = require 'webpack'
BackendConfig = require './backend'

module.exports = class BackendWatchConfig extends BackendConfig

  constructor: ->
    super

    @config.cache = true
    @config.debug = true
    unless @options.unsafeCache is false
      @config.module.resolve.unsafeCache = @options.unsafeCache
    @config.devtool = @options.backend.devtool ? @options.devtool

