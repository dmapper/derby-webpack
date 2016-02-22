_ = require 'lodash'
csswring = require 'csswring'
webpack = require 'webpack'
FrontendConfig = require './frontend'
ExtractTextPlugin = require 'extract-text-webpack-plugin'

module.exports = class FrontendBuildConfig extends FrontendConfig

  constructor: ->
    super
    _.defaultsDeep @options,
      frontend:
        productionSourceMaps: false

    @config.cache = false
    @config.debug = false
    if @options.frontend.productionSourceMaps
      @config.devtool = 'source-map'
    else
      delete @config.devtool

    @config.postcss = @_getPostCss [
      csswring() # minification
    ]

    @config.module.loaders = @config.module.loaders.concat [
      test: /\.css$/
      loader: ExtractTextPlugin.extract 'style-loader', "raw!postcss"
    ]

    @config.module.loaders = @config.module.loaders.concat @_getBeforeStylusLoaders()

    @config.module.loaders.push @_getStylusLoader()

    @config.plugins = @config.plugins.concat [
      new ExtractTextPlugin('[name].css')
      new webpack.optimize.UglifyJsPlugin({
        compress:
          warnings: false
      })
    ]

  _getActualStylusLoader: (args...) ->
    ExtractTextPlugin.extract 'style-loader', super args...