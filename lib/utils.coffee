shuffle = (array) ->
  i = array.length
  return if i is 0

  while --i
    j = Math.floor Math.random() * ( i + 1 )
    temp = array[i]
    array[i] = array[j]
    array[j] = temp

random = (max)-> Math.floor Math.random() * max

keygen = (length, options = {}) ->
  keys = []
  chars = "0123456789abcdefghijklmnopqrstuvwxyz"
  rest = length
  while --length
    rand = random chars.length
    upper = length * random(length) % 2
    char = chars.substring rand, rand+1
    unless options.lower
      char = if upper then char.toUpperCase() else char
    keys.push char
  keys.join ""
  shuffle(keys).join ""

ask = (question, {format, callback, error})->
  {stdin, stdout} = process
  stdout.write "#{question} "
  stdin.resume()
  stdin.setEncoding "utf8"
  stdin.once "data", (answer)->
    answer = answer.toString().trim()
    if format?.test? answer
      callback answer
    else
      if error
        error answer.toString().trim()
      else
        stdout.write "Please enter a valid answer.\n"
      ask question, {format, callback, error}

module.exports = {shuffle, random, keygen, ask}