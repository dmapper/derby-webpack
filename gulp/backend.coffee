gulp = require 'gulp'
webpack = require 'webpack'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
WebpackDevServer = require 'webpack-dev-server'
nodemon = require 'nodemon'

module.exports = (options) ->
  base = require('./base') options

  nodeModules = {}
  fs.readdirSync(options.dirname + '/node_modules')
    .filter (x) ->
      ['.bin'].indexOf(x) is -1
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
      new webpack.NormalModuleReplacementPlugin(/\.(styl|css)$/, 'node-noop')
      #new webpack.IgnorePlugin(/\.(css|styl)$/)
      #new webpack.BannerPlugin('require("source-map-support").install();',
      #                          { raw: true, entryOnly: false }),
      #new webpack.HotModuleReplacementPlugin({ quiet: true })
    ]

  gulp.task 'backend-build', (done) ->
    webpack(config).run onBuild(done)

  gulp.task 'backend-watch', (done) ->
    firedDone = false
    webpack(config).watch 100, (err, stats) ->
      unless firedDone
        firedDone = true
        done()
      nodemon.restart()
