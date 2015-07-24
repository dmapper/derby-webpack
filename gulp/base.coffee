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
        loaders: [__dirname + '/../loaders/derby-jade-loader']
      ,
        include: /\.coffee$/
        loader: "coffee"
        exclude: [
          /\/components\/.+\.coffee$/
          #/node_modules/
        ]
      ,
        include: /\/components\/.+\.coffee$/
        loaders: [__dirname + '/../loaders/derby-component-loader', 'coffee']
      ,
        include: /\.json$/
        loader: 'json'
      ]
    resolve:
      extensions: ['', '.json', '.js', '.coffee']

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
