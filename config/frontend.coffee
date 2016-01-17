fs = require 'fs'
_ = require 'lodash'
autoprefixer = require 'autoprefixer-core'
webpack = require 'webpack'
BaseConfig = require './base'

module.exports = class FrontendConfig extends BaseConfig

  constructor: ->
    super
    _.defaultsDeep @options,
      stylus: {}
      frontend:
        baseEntry: []
      webpackPort: 3010
      apps: ['app']

    @apps = @_sanitizeApps @options.apps
    @beforeStylusEntries = @_getBeforeStylusEntries @options.stylus

    @config.target = 'web'

    @config.entry = @_getEntries @apps, @options.frontend.baseEntry

    @config.module.loaders = @config.module.loaders.concat [
      include: /racer-highway\/lib\/browser\/index\.js$/
      loaders: [__dirname + '/../loaders/racer-highway-loader.js']
    ]
    # POSTCSS HERE

    @config.output =
      path: @options.dirname + '/build/client'
      pathInfo: true
      publicPath: "http://localhost:#{ @options.webpackPort }/build/client/"
      filename: '[name].js'

    @config.plugins = @config.plugins.concat [
      # Don't bundle server-specific modules on client
      new webpack.NormalModuleReplacementPlugin(
          /\.(server|server\.coffee|server\.js)$/,
          __dirname + '/../node_modules/node-noop')
    ]

    if devTool = @_getDevTool()
      @config.devtool = devTool

  _getHeaderEntry: -> [
    'racer-highway/lib/browser'
    'derby-parsing'
  ]

  _getBeforeStylusEntries: ->
    res = {}
    for appName, entry of @apps
      entry = if _.isArray(entry) then entry[0] else entry
      beforeStyl = entry + '/styles/before.styl'
      if fs.existsSync(beforeStyl)
        res[entry] = beforeStyl
    res

  _getPostCss: (plugins = []) ->
    DEFAULT_POSTCSS_PLUGINS = [
      autoprefixer(browsers: ['last 2 version', '> 1%', 'ie 10', 'android 4'])
    ]
    plugins = [plugins] unless _.isArray(plugins)
    ->
      DEFAULT_POSTCSS_PLUGINS.concat plugins

  _getDevTool: ->
    unless process.env.NODE_ENV is 'production'
      @options.frontend.devtool ? @options.devtool

  _getStylusParams: ->
    DEFAULT_STYLUS =
      'include css': true
    _.merge {}, @options.stylus, DEFAULT_STYLUS

  _getActualStylusLoader: (params = {}) ->
    params = _.merge {}, @_getStylusParams(), params
    strStylusParams = JSON.stringify params
    "raw!postcss!stylus?#{ strStylusParams }"

  # load styles/before.styl if it's present in point entry
  _getBeforeStylusLoaders: ->
    for entry, beforeStyl of @beforeStylusEntries
      do (entry) =>
        test: (absPath) ->
          /\.styl$/.test(absPath) and absPath.indexOf( entry ) isnt -1
        loader: @_getActualStylusLoader(import: [beforeStyl])

  _getStylusLoader: ->
    test: (absPath) ->
      return false unless /\.styl$/.test(absPath)
      # Don't process this if was processed previously by any entry-specific loader
      for entry, beforeStyl of @beforeStylusEntries
        if absPath.indexOf( entry ) isnt -1
          return false
      return true
    loader: @_getActualStylusLoader()
