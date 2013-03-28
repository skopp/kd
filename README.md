Koding CLI Tool
===============

This is the tool for Koding.

## Running

You can run modules simply calling

    kd module [command] [, params]

Examples:

    kd kite create mykite

This will run `./modules/kite.coffee:create("mykite")`.

## Modules

Modules are in `modules` directory. Every module is a file exporting a class.

This is an example with a name `mymodule.coffee`

    module.exports = class MyModule
    
      @help: """
      Koding MyModule Controller
      """
    
      hello: (name)->
        console.log "hello world #{name}"

The `@help` static is mandatory. When user call `kd mymodule` that information will be shown.

The example above can be run calling:

    kd mymodule hello koding

The output will be:

    hello world koding