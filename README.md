Koding CLI Tool
===============

This is the tool for Koding.

## Installing KD

    npm install -g kite

After installing KD, you will have a `kd` executable to use everywhere.

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

      constructor: (@config)->
    
      hello: (name)->
        console.log "hello world #{name}"

The `@help` static is mandatory. When user call `kd mymodule` that information will be shown.

`@config` variable is the `~/.kdconfig` file. It's a JSON file and you can set global variables using `config` module (write `kd config`).

The example above can be run calling:

    kd mymodule hello koding

The output will be:

    hello world koding

## Kite Module

Kite is the module for kite management in Koding.

### Creating a Kite

Creating a kite is simple:

    kd kite create mykite

Also you can create a kite with a key.

    kd kite create mykite mykitekey

As an example:

    kd kite create mykite 83949f9d9w939r9v9d93939t9f9d9939596003

You can now enter the kite directory with

    cd mykite

### Running the Kite

You can run a kite when you are in the current kite's directory.

    kd kite run

command will run the kite.

### Testing the Kite

When you create a kite, you will have a `test` directory in it. You can write and run tests using Mocha test framework.

    kd kite test

will run the tests.

### Configuring the Kite

Kites have `manifest.js` files. These files looks like:

    module.exports = {
        "name": "mykite",
        "apiAdress": "http://koding.com",
        "key": ""
    };

This is the configuration file and you can easily change values using the `kd` cli tool.

    kd kite manifest key 123456

After writing that command your manifest file will be something like that:

    module.exports = {
      "name": "mykite",
      "apiAdress": "http://koding.com",
      "key": "123456"
    };

Also you can add custom variables into manifest file using

    kd kite manifest key value
