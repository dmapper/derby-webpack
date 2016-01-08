gulp = require 'gulp'
webpack = require 'webpack'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
WebpackDevServer = require 'webpack-dev-server'
nodemon = require 'nodemon'
first = true

module.exports = (options) ->
  base = require('./base') options

  config = base.config
    entry: [
      #'webpack/hot/signal.js',
    ].concat(options.backend.entry || [options.dirname + '/server'])
    target: 'node'
    output:
      path: options.dirname + '/build'
      filename: 'backend.js'
    node:
      __dirname: true
      __filename: true

    # Treat any module in node_modules or required from any module
    # within node_modules as an external dependency.
    # Bundle only modules which are derby components.
    externals: do ->

      # Get list of modules excluding derby components (dm- or d-)
      nodeModules = fs.readdirSync(options.dirname + '/node_modules').filter (name) ->
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

    recordsPath: options.dirname + '/build/_records'
    plugins: [
      new webpack.NormalModuleReplacementPlugin(/\.(styl|css)$/, __dirname + '/../node_modules/node-noop')
      #new webpack.IgnorePlugin(/\.(css|styl)$/)
      new webpack.BannerPlugin([
        'try {'
      , '  require.resolve("source-map-support");'
      , '  require("source-map-support").install();'
      , '} catch(e) {'
      , '  require("derby-webpack/node_modules/source-map-support").install();'
      , '}'
      ].join(' '), { raw: true, entryOnly: false }),
      #new webpack.HotModuleReplacementPlugin({ quiet: true })
    ]

  if process.env.NODE_ENV is 'production'
    config.devtool = 'source-map'
  else
    config.devtool = options.backend.devtool ? (options.devtool ? 'source-map')

  gulp.task 'backend-build', (done) ->
    config.plugins = [
      new webpack.optimize.UglifyJsPlugin({
        compress:
          warnings: false
      })
    ].concat (config.plugins || [])

    webpack(config).run base.onBuild(done)

  gulp.task 'backend-watch', (done) ->
    firedDone = false
    webpack(config).watch 100, (err, stats) ->
      unless firedDone
        firedDone = true
        done()
      setTimeout ->
        if first
          first = false
        else
          nodemon.restart()
      , (options.restartTimeout || 0)
