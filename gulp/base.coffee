DeepMerge = require 'deep-merge'

deepmerge = DeepMerge (target, source, key) ->
  if target instanceof Array
    return [].concat(target, source)
  source

module.exports = (options) ->

  config =
    module:
      loaders: [
        test: /\.jade$/
        loaders: [__dirname + "/../loaders/derby-jade-loader?#{ if options.moduleMode then 'module' else '' }"]
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
    resolveLoader:
      root: __dirname + '/../node_modules'
    resolve:
      extensions: ['', '.json', '.js', '.yaml', '.coffee']

  unless options.unsafeCache is false
    config.resolve.unsafeCache = options.unsafeCache || true

  unless process.env.NODE_ENV is 'production'
    config.devtool = options.devtool ? 'source-map'
    config.debug = options.debug ? true

  config: (overrides) ->
    deepmerge config, (overrides || {})

  onBuild: (done) ->
    (err, stats) ->
      if err
        console.log 'Error', err
      else
        console.log stats.toString()
      done?()
