gulp = require 'gulp'
webpack = require 'webpack'
path = require 'path'
_ = require 'lodash'
WebpackDevServer = require 'webpack-dev-server'
autoprefixer = require('autoprefixer-core')
csswring = require('csswring')
_ = require 'lodash'
fs = require 'fs'
ExtractTextPlugin = require 'extract-text-webpack-plugin'

module.exports = (options) ->
  base = require('./base') options

  stylusParams = _.merge
    'include css': true
  , options.stylus || {}

  apps = {}
  # If apps are passed as array we treat them as folders in project root
  if _.isArray(options.apps)
    for appName in options.apps
      apps[appName] = options.dirname + '/' + appName
  else
    apps = options.apps

  beforeStylEntries = do ->
    res = {}
    for appName, entry of apps
      entry = if _.isArray(entry) then entry[0] else entry
      beforeStyl = entry + '/styles/before.styl'
      if fs.existsSync(beforeStyl)
        res[entry] = beforeStyl
    res

  config = base.config
    target: 'web'
    entry: do ->
      res = {}
      baseEntry = [
        __dirname + '/../node_modules/racer-highway/lib/browser'
        options.dirname + '/node_modules/derby-parsing'
      ].concat (options.frontend.baseEntry || [])

      for appName, entry of apps
        entry = [entry] unless _.isArray(entry)
        res[appName] = baseEntry.concat entry
      res

    module:
      loaders: [
        include: /racer-highway\/lib\/browser\/index\.js$/
        loaders: [__dirname + '/../loaders/racer-highway-loader.js']
      ]
    postcss: ->
      [
        autoprefixer(browsers: ['last 2 version', '> 1%', 'ie 10', 'android 4'])
      ]

    output:
      path: options.dirname + '/build/client'
      pathInfo: true
      publicPath: "http://localhost:#{ options.webpackPort }/build/client/"
      filename: '[name].js'
    plugins: [
      # Don't bundle server-specific modules on client
      new webpack.NormalModuleReplacementPlugin(/\.(server|server\.coffee|server\.js)$/, __dirname + '/../node_modules/node-noop')
    ]

  # ----------------------------------------------------------------
  #   Build (Production)
  # ----------------------------------------------------------------

  gulp.task 'frontend-build', (done) ->

    config.postcss = ->
      [
        autoprefixer(browsers: ['last 2 version', '> 1%', 'ie 10', 'android 4'])
        csswring() # minification
      ]

    config.module.loaders.push
      test: /\.css$/
      loader: ExtractTextPlugin.extract 'style-loader', "raw!postcss"

    # load styles/before.styl if it's present in point entry
    config.module.loaders = config.module.loaders.concat (
      for entry, beforeStyl of beforeStylEntries
        do (entry, stylusParams = _.cloneDeep(stylusParams)) ->
          stylusParams.import = [beforeStyl]
          test: (absPath) ->
            /\.styl$/.test(absPath) and absPath.indexOf( entry ) isnt -1
          loader: ExtractTextPlugin.extract 'style-loader', "raw!postcss!stylus?#{ JSON.stringify stylusParams }"
    )
    config.module.loaders.push
      test: (absPath) ->
        return false unless /\.styl$/.test(absPath)
        # Don't process this if was processed previously by any entry-specific loader
        for entry, beforeStyl of beforeStylEntries
          if absPath.indexOf( entry ) isnt -1
            return false
        return true
      loader: ExtractTextPlugin.extract 'style-loader', "raw!postcss!stylus?#{ JSON.stringify stylusParams }"

    config.plugins = [
      new ExtractTextPlugin('[name].css')
      new webpack.optimize.UglifyJsPlugin({
        compress:
          warnings: false
      })
    ].concat (config.plugins || [])

    webpack(config).run base.onBuild(done)

  # ----------------------------------------------------------------
  #   Watch (Development)
  # ----------------------------------------------------------------

  gulp.task 'frontend-watch', ->

    config.module.loaders.push
      test: /\.css$/
      loader: "style!raw!postcss"

    # load styles/before.styl if it's present in point entry
    config.module.loaders = config.module.loaders.concat (
      for entry, beforeStyl of beforeStylEntries
        do (entry, stylusParams = _.cloneDeep(stylusParams)) ->
          stylusParams.import = [beforeStyl]
          test: (absPath) ->
            /\.styl$/.test(absPath) and absPath.indexOf( entry ) isnt -1
          loader: "style!raw!postcss!stylus?#{ JSON.stringify stylusParams }"
    )
    config.module.loaders.push
      test: (absPath) ->
        return false unless /\.styl$/.test(absPath)
        # Don't process this if was processed previously by any entry-specific loader
        for entry, beforeStyl of beforeStylEntries
          if absPath.indexOf( entry ) isnt -1
            return false
        return true
      loader: "style!raw!postcss!stylus?#{ JSON.stringify stylusParams }"

    # Add webpack-dev-server and hot reloading
    for name, entry of config.entry
      config.entry[name] = [
        __dirname + '/../node_modules/webpack-dev-server/client?http://localhost:' + options.webpackPort
        __dirname + '/../node_modules/webpack/hot/dev-server'
        __dirname + '/../wdsVisual'
      ].concat (entry || [])
      
    config.plugins = [
      new webpack.HotModuleReplacementPlugin(quiet: true)
    ].concat (config.plugins || [])

    new WebpackDevServer(webpack(config),
      publicPath: '/build/client/'
      hot: true
      inline: true
      stats: colors: true
      noInfo: true
    ).listen options.webpackPort, 'localhost', (err, result) ->
      if err
        console.log err
      else
        console.log "webpack dev server listening at localhost:#{ options.webpackPort }"
