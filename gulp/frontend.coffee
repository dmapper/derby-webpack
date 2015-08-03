gulp = require 'gulp'
webpack = require 'webpack'
path = require 'path'
_ = require 'lodash'
WebpackDevServer = require 'webpack-dev-server'
autoprefixer = require('autoprefixer-core')
csswring = require('csswring')

module.exports = (options) ->
  base = require('./base') options

  config = base.config
    target: 'web'
    entry:
      app: [
        __dirname + '/../node_modules/racer-highway/lib/browser'
        options.dirname + '/node_modules/derby-parsing'
      ].concat(options.frontend.entry || [options.dirname + '/app'])
    module:
      loaders: [
        test: /\.css$/
        loader: 'style!css?module&localIdentName=[component]-[local]!postcss'
      ,
        test: /\.styl$/
        loader: 'style!css?module&localIdentName=[component]-[local]!postcss!stylus'
      ,
        include: /racer-highway\/lib\/browser\.js$/
        loaders: [__dirname + '/../loaders/racer-highway-loader.js']
      ]
    postcss: ->
      [
        autoprefixer(browsers: ['last 2 version', '> 1%', 'ie 10', 'android 4'])
        #csswring # minification
      ]

    output:
      path: options.dirname + '/build/client'
      pathInfo: true
      publicPath: "http://localhost:#{ options.webpackPort }/build/client/"
      filename: '[name].js'
    plugins: []
    stylus: options.stylus || {}

  # Add webpack-dev-server and hot reloading
  if process.env.NODE_ENV isnt 'production'
    for name, entry of config.entry
      config.entry[name] = [
        __dirname + '/../node_modules/webpack-dev-server/client?http://localhost:' + options.webpackPort
        __dirname + '/../node_modules/webpack/hot/dev-server'
      ].concat (entry || [])
    config.plugins = [
      new webpack.HotModuleReplacementPlugin(quiet: true)
    ].concat (config.plugins || [])

  gulp.task 'frontend-build', (done) ->
    process.env.NODE_ENV = 'production'
    webpack(config).run base.onBuild(done)

  gulp.task 'frontend-watch', ->
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
