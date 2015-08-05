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
        loaders: [__dirname + "/../loaders/derby-jade-loader?#{ options.moduleMode ? 'module' : '' }"]
      ,
        include: /\.coffee$/
        loader: "coffee"
        exclude: options.componentsPaths
      ,
        include: options.componentsPaths
        loaders: [__dirname + '/../loaders/derby-component-loader', 'coffee']
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

  unless process.env.NODE_ENV is 'production'
    config.devtool = 'source-map'
    config.debug = true

  config: (overrides) ->
    deepmerge config, (overrides || {})

  onBuild: (done) ->
    (err, stats) ->
      if err
        console.log 'Error', err
      else
        console.log stats.toString()
      done?()
