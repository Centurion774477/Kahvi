# Kahvi
CoffeeScript on its own allows you to write apps much faster than with plain JavaScript, however, you still have to jump over verbose hurdles like `x = document.getElementById 'some-id'` or `x.addEventListener ...`. I wrote Kahvi -- nicknamed French Press CoffeeScript -- to solve these problems. And yes, the name is inspired by Ruby on Rails.

French Press CoffeeScript doesn't get in your way for your actual app logic; it only helps you get there faster; there are no magical conventions over things, just faster and cleaner ways. Let's get into the actual syntax of French Press CoffeeScript.

Kahvi currently only has five special expressions/functions.

First:

```coffeescript
when ‘some-button-id’ is clicked ->
  console.log “some button was clicked”
```

This is a shorthand for event listeners, but it also pulls down the element implicitly, cutting down on a lot of boilerplate.

Here is the CoffeeScript version:

```coffeescript
document.getElementById('some-button-id').addEventListener 'clicked', () ->
  console.log “some button was clicked”
```

In place of 'clicked', you can also pass these other options:
- submitted
- highlighted/mousedover
- unhighlighted/mouseoff
- Typed/typing
- changed

Another example:

```coffeescript
when ‘some-button-id’ is mousedover ->
  console.log “some button was moused over”
```

Second:

```
enforce ‘some-id' as a word
```

This is a bit more magical than the first expression, but it's really just verifying input -- an action that is otherwise extremely tedious.

Code speaks louder than words, however, so let me show you the CoffeeScript equivalent:

```coffeescript
unless document.getElementById ‘some-id’.value.match /^[a-zA-Z]+$/
  alert “input rejected: it must be a string.”
  return
```

Long story short, it will alert with a default message saying the input was rejected because it must be <type> unless it matches the requirements.
I haven't added it yet, but in the future it will perform a second check for null values or empty inputs to give a more detailed alert.

As of now, there is only one other alternative type: integer/number.

You can also use string as an alias to word.

Third:

```coffeescript
someButton refers to ‘some-button-id’
```

This is really just assigning someButton to 'some-button-id'. Here's the equivalent CoffeeScript:

```coffeescript
someButton = document.querySelector ‘some-button-id’
```

The fourth and fifth features are just one word functions:

`hide x`

Evaluates to

`x.style.display = ‘none’`

And its opposite:

`display x`

Evaluates to

`x.style.display = ‘block’`

That's French Press CoffeeScript! More will come in the future like the null check I mentioned earlier but I'll maintain the same idea from earlier: French Press CoffeeScript not getting in your way for your actual app logic.

Hope you enjoyed, cheers!
