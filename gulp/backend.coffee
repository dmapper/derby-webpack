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

  nodeModules = {}
  fs.readdirSync(options.dirname + '/node_modules')
    .filter (name) ->
      # Bundle only derby components from node_modules
      name isnt '.bin' and not /^dm-/.test(name) and not /^d-/.test(name)
    .forEach (mod) ->
      nodeModules[mod] = 'commonjs ' + mod

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
    externals: nodeModules
    recordsPath: options.dirname + '/build/_records'
    plugins: [
      new webpack.NormalModuleReplacementPlugin(/\.(styl|css)$/, __dirname + '/../node_modules/node-noop')
      #new webpack.IgnorePlugin(/\.(css|styl)$/)
      #new webpack.BannerPlugin('require("source-map-support").install();',
      #                          { raw: true, entryOnly: false }),
      #new webpack.HotModuleReplacementPlugin({ quiet: true })
    ]

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
