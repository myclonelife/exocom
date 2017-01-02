require! {
  'chalk' : {cyan, dim, green, red, magenta, yellow}
  'docopt' : {docopt}
  'nitroglycerin' : N
  '../package.json' : {name, version}
  '../package.json' : {version}
  'path'
  './exocom' : ExoCom
}


console.log dim "ExoCom #{version}\n"

doc = """
Provides Exosphere communication infrastructure services in development mode.

Usage:
  #{name} [PORT=<port>]
  #{name} -h | --help
  #{name} -v | --version
"""
options = docopt doc, help: no

switch
| options['-h'] or options['--help']     =>  console.log doc
| options['-v'] or options['--version']  =>
| otherwise                              =>  run!



function run
  exocom = new ExoCom service-messages: process.env.SERVICE_MESSAGES
    ..on 'error', on-error
    ..on 'http-online', on-http-online
    ..on 'message', on-message
    ..on 'routing-setup', on-routing-setup
    ..on 'warn', on-warn
    ..on 'websockets-online', on-websockets-online
    ..listen (+process.env.PORT or 3100)


function on-websockets-online port
  console.log "ExoCom WebSocket listener online at port #{cyan port}"


function on-http-online port
  console.log "ExoCom HTTP service online at port #{magenta port}"


function on-error err
  console.log red "Error: #{err}"
  process.exit 1


function on-warn warning
  console.log yellow "Warning: #{warning}"


function on-message {messages, receivers}
  for message in messages
    response-time = ''
    if message.response-to
      response-time = "  (#{(message.response-time * 1e-6).to-fixed 2} ms)"
    if message.name is message.original-name
      console.log "#{message.sender}  --[ #{message.name} ]->  #{receivers.join ' and '}#{response-time}"
    else
      console.log "#{message.sender}  --[ #{message.original-name} ]-[ #{message.name} ]->  #{receivers.join ' and '}#{response-time}"
    console.log message.payload


function on-routing-setup
  console.log 'receiving routing setup:'
  for command, routing of exocom.client-registry.routes
    process.stdout.write "  --[ #{command} ]-> "
    text = for receiver in routing.receivers
      "#{receiver.name}"
    process.stdout.write "#{text.join ' + '}\n"
