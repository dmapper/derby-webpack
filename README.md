# derby-webpack
> Derby.js client and server bundling through Webpack.

## Usage

TBD

## Why

Browserify doesn't allow to incrementally rebuild the bundle (doesn't have this feature built in).
And as the application grows, compilation of `coffee`/`jade`/`stylus` and `derby views` takes too much time.
This is the prototype of Derby.js app which uses Webpack for client bundling and hot reloading of styles 
(views and components are also being hot reloaded but they currently apply changes via client-side page refresh).

## Caveats

`tag`, `attributes`, `arrays` when defining derby templates are not supported yet.
So right now you have to always use `view(is='template')` when calling a template.
And you can specify `attributes` or `arrays` when you call the template like this:

```
view(is='template')
  attribute(is='title') Hello
  array(is='tab' title='One') Ping
  array(is='tab' title='Two') Pong
```
## Linters
### Stylus linter
Linter documentation [here](https://github.com/rossPatton/stylint).
Configuration properties [here](https://github.com/rossPatton/stylint#custom-configuration).
[Stylint](https://www.npmjs.com/package/stylint) and [Stylint-loader](https://github.com/guerrero/stylint-loader) loader should be installed to use stylint.

### Coffee Linter 
Linter documentation [here](http://www.coffeelint.org/).
[Coffelint](http://www.coffeelint.org/) and [coffeelint-loader](https://github.com/bline/coffeelint-loader) loader should be installed to use coffeeLinter.

## MIT Licence

Copyright (c) 2015 Pavel Zhukov
