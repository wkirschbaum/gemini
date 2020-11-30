# Gemini

**Naive and incomplete Gemini server**

https://gemini.circumlunar.space/

## WARNING
This code is for learning and should not be used in any production
system

## How to use this project

    mix deps.get
    mix run --no-halt

Note the *mock* certificates in the root folder for ssl. Please
generate your own if you want to use this outside of this example.


Use any gemini client to access localhost:1965 to see `Hello, World!`
returned. Specifications from
https://gemini.circumlunar.space/docs/specification.html and tested
against `emacs elpher`.
