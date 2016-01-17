fs = require 'fs'
_ = require 'lodash'
webpack = require 'webpack'
BaseConfig = require './base'

module.exports = class BackendConfig extends BaseConfig

  constructor: ->
    super
    _.defaults @options,
      backend: {}
      backendApps: ['server']

    @apps = @_sanitizeApps @options.backendApps

    @config.target = 'node'

    @config.entry = @_getEntries @apps, @options.backend.baseEntry

    @config.output =
      path: @options.dirname + '/build'
      filename: '[name].js'

    @config.node =
      __dirname: true
      __filename: true

    @config.externals = @_getExternalsFn()

    @config.recordsPath = @options.dirname + '/build/_records'

    @config.plugins = [
      new webpack.NormalModuleReplacementPlugin(/\.(styl|css)$/, __dirname + '/../node_modules/node-noop')
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

    # Get list of modules excluding derby components (dm- or d-)
    nodeModules = fs.readdirSync(@options.dirname + '/node_modules').filter (name) ->
      name isnt '.bin' and not /^dm-/.test(name) and not /^d-/.test(name)

    (context, request, cb) ->
      inModules = false
      for moduleName in nodeModules
        if /// node_modules\/#{ moduleName } ///.test(context) or
            /// ^#{ moduleName } ///.test(request)
          inModules = true
          break
      if inModules
        cb null, "commonjs #{ request }"
      else
        cb()

  _getDevTool: ->
    @options.backend.devtool ? @options.devtool
