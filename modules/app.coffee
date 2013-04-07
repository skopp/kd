module.exports = class App
  constructor: (@config)->

  test: (x, y)->
    console.log x, y, @options.a