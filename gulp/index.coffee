gulp = require 'gulp'
nodemon = require 'nodemon'
path = require 'path'
_ = require 'lodash'

module.exports = (options = {}) ->
  _.defaults options,
    dirname: path.dirname path.dirname path.dirname __dirname
    frontend: {}
    backend: {}
    webpackPort: 3010
    serverPort: 3000
    moduleMode: false
    apps: ['app']

  require('./frontend') options
  require('./backend') options

  gulp.task 'build', ['frontend-build', 'backend-build']
  gulp.task 'watch', ['frontend-watch', 'backend-watch']

  gulp.task 'run', ['frontend-watch', 'backend-watch'], ->
    nodemon(
      execMap:
        js: 'node'
      script: options.dirname + '/build/backend'
      ignore: ['*']
      watch: ['foo/']
      ext: 'noop'
    ).on 'restart', ->
      #console.log 'Patched!'
