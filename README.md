Koding CLI Task Manager
=======================

This is the tool for Koding.

## Quick Install

    [sudo] npm install -g kd
    echo '. <(kd completion shell)' >> .profile
    echo '. <(kd config --aliases)' >> .profile

## Installing KD

    [sudo] npm install -g kd

After installing KD, you will have a `kd` executable to use everywhere.

## Enabling BASH/ZSH Autocompletion

KD has autocompletion feature for its modules. You can enable it writing the following command after install.

    kd completion bash|sh

or if you use ZSH you should write zsh instead of bash

    kd completion zsh|sh

## Running

You can run modules simply calling

    kd module [command] [, subcommands] [, params]

Examples:

    kd kite create mykite --key x

This will run `./modules/kite.coffee:create("mykite")` with binding `{options: {key: 'x'}}`.

You can define subcommands:

    kd module command sub1 sub2 --paramkey paramval --paramkey1 paramval1 --parambool

This command will match these pattern:

```coffeescript
module.exports = class Module
  command: (sub1, sub2)->
    {paramkey, paramkey1, parambool} = @options

    # paramkey is paramval
    # paramkey1 is paramval1
    # parambool is true
```

## Modules

Modules are in `modules` directory. Every module is a file exporting a class.

Also you can create your modules in `.kd/modules` directory.

This is an example with a name `mymodule.coffee`

```coffeescript
module.exports = class MyModule

  # This closes the errors of the command. Not recommended.
  silent: yes

  help: """
  Koding MyModule Controller
  """

  alias:
    hi: "hello"

  constructor: (@config)->

  hello: (name)->
    {with} = @options
    console.log "hello #{name} and #{with}"

  __command: (command, params)->
    # magic command
```

### Kodingfile.coffee

You also can use `kd` with `Kodingfile.coffee` file. If a directory has that file kd will run it.
The command shouldn't be a module name. Because kd will search for existing modules first. Kodingfile
is the latest one it looks.

While using Kodingfile, you should use only the command name:

```coffeescript
module.exports = class Kodingfile
  hello: (name)->
    console.log "Hello, #{name}"
```

will run with

    kd hello fka

This command will search for "hello" module first, won't find and will look for your Kodingfile.coffee.

### Modules Meta

The `help` is an help to show user. When user call `kd mymodule` that information will be shown.

`@config` variable is the `~/.kdconfig` file. It's a JSON file and you can set global variables using `config` module (write `kd config`).

If you write `__command` into your module class, your module will never give a error about command existance. It'll call that method.

You can use `alias` to make aliases.

The example above can be run calling:

    kd mymodule hello koding --with birds

or with the alias:

    kd mymodule hello koding --with birds

The output will be:

    hello koding and birds

## Kite Module

Kite is the module for kite management in Koding.

### Creating a Kite

Creating a kite is simple:

    kd kite create --name mykite

Also you can create a kite with a key.

    kd kite create --name mykite --key mykitekey

As an example:

    kd kite create --name mykite --key 83949f9d9w939r9v9d93939t9f9d9939596003

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

Kites have `.manifest.yml` files. These files looks like:

```yaml
name": mykite
apiAdress: "http://koding.com
key: ""
```

This is the configuration file and you can easily change values using the `kd` cli tool.

    kd kite manifest --key=123456

or

    kd kite manifest -k 123456

After writing that command your manifest file will be something like that:

```yaml
name": mykite
apiAdress: "http://koding.com
key: 123456
```

Also you can add custom variables into manifest file using

    kd kite manifest --key=key --value=value

## App Module

You can manage apps using KD CLI tool.

### Compiling Koding App

When you are in KD App directory, you can use `compile` command to compile the application.

    kd app compile

This will compile your application files and generate an `index.js`

### Syncing Koding App

As you know, you have FTPS for your Koding. When you want to put a file into your Koding from your computer,
you can connect to FTP.

When you create an app in your computer you can sync it with your Koding host. You should install `lftp` first.

    brew install lftp

or

    sudo apt-get install lftp

And you will be able to use that command to sync your app.

    cd yourapp.kdapp
    kd app sync

This will update your app.

---
## LICENSE

License information has not been detailed yet.
