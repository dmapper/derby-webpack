defaults = require 'lodash/defaults'
isArray = require 'lodash/isArray'

module.exports = class BaseConfig

  constructor: (@options = {}) ->

    defaults @options,
      noParse: undefined
      unsafeCache: true
      dirname: process.cwd()
      moduleMode: false
      devtool: 'source-map'
      preLoaders: []

    @config = {}
    if @options.moduleConfigs?
      for key, val of @options.moduleConfigs
        @config[key] = val

    @config.module =
      loaders: [
        test: /\.jade$/
        loaders: [__dirname + "/../loaders/derby-jade-loader?#{ if @options.moduleMode then 'module' else '' }"]
      ,
        include: /\.coffee$/
        loaders: [__dirname + '/../loaders/derby-loader', 'coffee']
      ,
        include: /\.js$/
        loaders: [__dirname + '/../loaders/derby-loader']
      ,
        include: /\.json$/
        loader: 'json'
      ,
        include: /\.yaml$/
        loader: 'json!yaml'
      ]

    # Append additional loaders to the beginning of default loaders array
    if @options.loaders? and isArray(@options.loaders)
      @config.module.loaders = @options.loaders.concat @config.module.loaders

    @config.resolveLoader =
      root: __dirname + '/../node_modules'
      fallback: __dirname + '/../..'

    @config.resolve =
      extensions: ['', '.json', '.js', '.yaml', '.coffee']
      fallback: __dirname + '/../..'

    if @options.resolve?.alias?
      @config.resolve.alias = @options.resolve.alias

    @config.plugins = []

    if bundleAnalyzer = @options.bundleAnalyzer
      BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
      @config.plugins.push new BundleAnalyzerPlugin(bundleAnalyzer)

    if @options.preLoaders?
      @config.module.preLoaders = @options.preLoaders

    if @options.postLoaders?
      @config.module.postLoaders = @options.postLoaders

    if @options.noParse?
      @config.module.noParse = @options.noParse

  _sanitizeApps: (apps) ->
    res = {}
    # If apps are passed as array we treat them as folders in project root
    if isArray(apps)
      for appName in apps
        res[appName] = @options.dirname + '/' + appName
    else
      res = apps
    res

  _getHeaderEntry: -> []

  _getEntries: (apps, baseEntry = []) ->
    baseEntry = @_getHeaderEntry().concat(baseEntry)
    res = {}
    for appName, entry of apps
      entry = [entry] unless isArray(entry)
      res[appName] = baseEntry.concat entry
    res
