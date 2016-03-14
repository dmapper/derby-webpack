_ = require 'lodash'
csswring = require 'csswring'
webpack = require 'webpack'
FrontendConfig = require './frontend'
ExtractTextPlugin = require 'extract-text-webpack-plugin'
AssetsPlugin = require 'assets-webpack-plugin'

module.exports = class FrontendBuildConfig extends FrontendConfig

  constructor: ->
    super
    _.defaultsDeep @options,
      frontend:
        productionSourceMaps: false
        cache: false
        uglify: true

    # Add hash to bundles' filenames for long-term caching in production
    @config.output.filename = '[name].[hash].js'

    @config.cache = @options.frontend.cache
    @config.debug = false
    if @options.frontend.productionSourceMaps
      @config.devtool = 'source-map'

    @config.postcss = @_getPostCss [
      csswring() # minification
    ]

    @config.stats ?= {}
    @config.stats.children ?= false

    @config.module.loaders = @config.module.loaders.concat [
      test: /\.css$/
      loader: ExtractTextPlugin.extract 'style-loader', "raw!postcss"
    ]

    @config.module.loaders = @config.module.loaders.concat @_getBeforeStylusLoaders()

    @config.module.loaders.push @_getStylusLoader()

    @config.plugins.push new ExtractTextPlugin('[name].css', priorityModules: (@options.priorityModules || []))

    if @options.frontend.uglify
      uglifyOptions =
        compress:
          warnings: false
      unless @options.frontend.productionSourceMaps
        uglifyOptions.sourceMap = false
      @config.plugins.push new webpack.optimize.UglifyJsPlugin(uglifyOptions)

    # Write hash info metadata into json file
    @config.plugins.push new AssetsPlugin({
      filename: 'assets.json'
      fullPath: false
      path: @config.output.path
    })

  _getActualStylusLoader: (args...) ->
    ExtractTextPlugin.extract 'style-loader', super args...