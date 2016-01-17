_ = require 'lodash'

module.exports = class BaseConfig

  constructor: (@options = {}) ->

    _.defaults @options,
      noParse: undefined
      unsafeCache: true
      dirname: process.cwd()
      moduleMode: false
      devtool: 'source-map'

    @config = {}

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

    @config.resolveLoader =
      root: __dirname + '/../node_modules'

    @config.resolve =
      extensions: ['', '.json', '.js', '.yaml', '.coffee']

    @config.plugins = []

    if @options.noParse?
      @config.module.noParse = @options.noParse

  _sanitizeApps: (apps) ->
    res = {}
    # If apps are passed as array we treat them as folders in project root
    if _.isArray(apps)
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
      entry = [entry] unless _.isArray(entry)
      res[appName] = baseEntry.concat entry
    res
