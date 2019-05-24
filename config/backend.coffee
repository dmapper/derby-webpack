fs = require 'fs'
defaults = require 'lodash/defaults'
isArray = require 'lodash/isArray'
flatten = require 'lodash/flatten'
webpack = require 'webpack'
BaseConfig = require './base'

module.exports = class BackendConfig extends BaseConfig

  constructor: ->
    super
    defaults @options,
      backend: {}
    @options.backendApps = ['server'] unless @options.backendApps

    @apps = @_sanitizeApps @options.backendApps

    @config.target = 'node'

    @config.entry = @_getEntries @apps, @options.backend.baseEntry

    # Append additional loaders to the beginning of default loaders array
    if @options.backend?.loaders? and isArray(@options.backend.loaders)
      @config.module.loaders = @options.backend.loaders.concat @config.module.loaders

    if @options.backend?.preLoaders? and isArray(@options.backend.preLoaders)
      @config.module.preLoaders = @options.backend.preLoaders.concat (@config.module.preLoaders || [])

    if @options.backend?.postLoaders? and isArray(@options.backend.postLoaders)
      @config.module.postLoaders = @options.backend.postLoaders.concat (@config.module.postLoaders || [])

    if @options.backend?.resolve?.alias?
      @config.resolve.alias = @options.backend.resolve.alias

    @config.output =
      path: @options.dirname + '/build'
      filename: '[name].js'

    @config.node =
      __dirname: true
      __filename: true

    @config.externals = @_getExternalsFn()

    @config.recordsPath = @options.dirname + '/build/_records'

    @config.plugins = [
      new webpack.NormalModuleReplacementPlugin(/\.(styl|css)$/, require.resolve('node-noop'))
      new webpack.BannerPlugin([
        'try {'
      , '  require.resolve("source-map-support");'
      , '  require("source-map-support").install();'
      , '} catch(e) {'
      , '  require("derby-webpack/node_modules/source-map-support").install();'
      , '}'
      ].join(' '), { raw: true, entryOnly: false })
    ]

  # Treat any module in node_modules or required from any module
  # within node_modules as an external dependency.
  # Bundle only modules which are derby components.
  _getExternalsFn: ->
    npmScopes = @options?.npmScopes || []
    includeList = @options?.includeList || []

    # Get list of modules excluding derby components (dm- or d-)
    nodeModules = fs.readdirSync(@options.dirname + '/node_modules').filter (name) =>
      name isnt '.bin'
    .map (name) =>
      if npmScopes.indexOf(name) isnt -1
        return fs.readdirSync(@options.dirname + '/node_modules/' + name).map (subname) =>
          name + '/' + subname
      return name

    nodeModules = flatten nodeModules

    nodeModules = nodeModules.filter (name) =>
      includeList.indexOf(name) is -1

    (context, request, cb) ->
      inModules = false
      for moduleName in nodeModules
        if /// node_modules\/#{ moduleName }(?:$|\/) ///.test(context) or
            /// ^#{ moduleName }(?:$|\/) ///.test(request)
          inModules = true
          break
      if inModules
        cb null, "commonjs #{ request }"
      else
        cb()
