fs = require 'fs'
defaults = require 'lodash/defaults'
isArray = require 'lodash/isArray'
merge = require 'lodash/merge'
autoprefixer = require 'autoprefixer'
postcssFilenamePrefix = require 'postcss-filename-prefix'
webpack = require 'webpack'
BaseConfig = require './base'
url = require 'url'

module.exports = class FrontendConfig extends BaseConfig

  constructor: ->
    super
    defaults @options,
      stylus: {}
      frontend: {}

    # If DEVSERVER_URL is specified, get port from it
    if process.env.DEVSERVER_URL
      @options.webpackPort = url.parse(process.env.DEVSERVER_URL).port || process.env.DEVSERVER_PORT || 80

    @options.webpackPort ?= process.env.DEVSERVER_PORT || 3010
    @options.webpackUrl ?= process.env.DEVSERVER_URL || "http://localhost:#{ @options.webpackPort }"

    @options.apps = ['app'] unless @options.apps

    @apps = @_sanitizeApps @options.apps
    @beforeStylusEntries = @_getBeforeStylusEntries()

    @config.target = 'web'

    @config.entry = @_getEntries @apps, @options.frontend.baseEntry

    @config.module.loaders = @config.module.loaders.concat [
      include: /racer-highway\/lib\/browser\/index\.js$/
      loaders: [__dirname + '/../loaders/racer-highway-loader.js']
    ]

    # Append additional loaders to the beginning of default loaders array
    if @options.frontend?.loaders? and isArray(@options.frontend.loaders)
      @config.module.loaders = @options.frontend.loaders.concat @config.module.loaders

    if @options.frontend?.preLoaders? and isArray(@options.frontend.preLoaders)
      @config.module.preLoaders = @options.frontend.preLoaders.concat (@config.module.preLoaders || [])

    if @options.frontend?.postLoaders? and isArray(@options.frontend.postLoaders)
      @config.module.postLoaders = @options.frontend.postLoaders.concat (@config.module.postLoaders || [])

    if @options.frontend?.resolve?.alias?
      @config.resolve.alias = @options.frontend.resolve.alias

    @config.output =
      path: @options.dirname + '/build/client'
      pathInfo: true
      publicPath: "http://localhost:#{ @options.webpackPort }/build/client/"
      filename: '[name].js'

    @config.plugins = @config.plugins.concat [
      # Don't bundle server-specific modules on client
      new webpack.NormalModuleReplacementPlugin(
          /\.(server|server\.coffee|server\.js)$/, require.resolve('node-noop'))
    ]

  _getHeaderEntry: -> [
    'racer-highway/lib/browser'
    'derby-parsing'
  ]

  _getBeforeStylusEntries: ->
    res = {}
    for appName, entry of @apps
      entry = if isArray(entry) then entry[0] else entry
      beforeStyl = entry + '/styles/before.styl'
      if fs.existsSync(beforeStyl)
        res[entry] = beforeStyl
    res

  _getPostCss: (plugins = []) ->
    DEFAULT_POSTCSS_PLUGINS = [
      autoprefixer(browsers: ['last 2 version', '> 1%', 'ie 10', 'android 4'])
    ]
    if @options.moduleMode
      DEFAULT_POSTCSS_PLUGINS.push postcssFilenamePrefix()
    plugins = [plugins] unless isArray(plugins)
    ->
      DEFAULT_POSTCSS_PLUGINS.concat plugins

  _getStylusParams: ->
    DEFAULT_STYLUS =
      'include css': true
    merge {}, @options.stylus, DEFAULT_STYLUS

  _getActualStylusLoader: (params = {}) ->
    params = merge {}, @_getStylusParams(), params
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
    do (beforeStylusEntries = @beforeStylusEntries) =>
      stylusImports = @options.stylusImports || []
      result = for item in stylusImports when item.test
        do ({ test, import: _import } = item) =>
          test: (absPath) ->
            return false unless /\.styl$/.test(absPath)
            shouldCompiled = true
            for entry, beforeStyl of beforeStylusEntries
              if absPath.indexOf( entry ) isnt -1
                shouldCompiled = false
                break
            shouldCompiled and new RegExp(test).test absPath
          loader: @_getActualStylusLoader(import: _import)

      # Don't process this if was processed
      # previously by any entry-specific loader
      result.push
        test: (absPath) =>
          return false unless /\.styl$/.test(absPath)
          shouldCompiled = true
          for entry, beforeStyl of beforeStylusEntries
            if absPath.indexOf( entry ) isnt -1
              shouldCompiled = false
              break
          shouldCompiled and
            for item in stylusImports when test = item.test
              if new RegExp(test).test absPath
                shouldCompiled = false
                break
          shouldCompiled
        loader: @_getActualStylusLoader()
      result
