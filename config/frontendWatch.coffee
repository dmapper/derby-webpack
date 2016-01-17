_ = require 'lodash'
webpack = require 'webpack'
FrontendConfig = require './frontend'

module.exports = class FrontendWatchConfig extends FrontendConfig

  constructor: ->
    super

    @config.cache = true
    @config.debug = true
    unless @options.unsafeCache is false
      @config.module.resolve.unsafeCache = @options.unsafeCache
    @config.devtool = @options.frontend.devtool ? @options.devtool

    @config.postcss = @_getPostCss()

    @config.module.loaders = @config.module.loaders.concat [
      test: /\.css$/
      loader: "style!raw!postcss"
    ]

    @config.module.loaders = @config.module.loaders.concat @_getBeforeStylusLoaders()

    @config.module.loaders.push @_getStylusLoader()

    @_initDevConfig()

  _getActualStylusLoader: ->
    'style!' + @_getActualStylusLoader()

  # Configure webpack-dev-server and hot reloading
  _initDevConfig: ->

    for name, entry of @config.entry
      @config.entry[name] = [
        'webpack-dev-server/client?http://localhost:' + @options.webpackPort
        'webpack/hot/dev-server'
        __dirname + '/../wdsVisual'
      ].concat (entry || [])

    @config.plugins = @config.plugins.concat [
      new webpack.HotModuleReplacementPlugin(quiet: true)
    ]

    @config.devServer =
      publicPath: '/build/client/'
      hot: true
      inline: true
      lazy: false
      stats: colors: true
      noInfo: true
      headers: 'Access-Control-Allow-Origin': '*'
      host: 'localhost'
      port: @options.webpackPort
