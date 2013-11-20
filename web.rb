require 'thin'
require 'sinatra'
require 'slim'
require 'rinruby'
require 'pry' 

set :slim, :pretty => true

get '/' do
  R.x = 3
  R.eval <<EOF
  output = x+1
EOF
  @output = R.output
#  binding.pry
  slim :index
end

__END__
@@layout
doctype html
html
  head
    title Slim
    meta charset="utf-8"
      
  body
    header
      h1 
       a href="http://bbdesignproject.wordpress.com" Bonnie's prototype website	
    
    == yield
    
  footer
    small
      | This is some tiny text at the bottom! Yay!

@@index
p
  | This a test using Sinatra web framework in Ruby, deployed via Heroku. Lots of pieces of technology are working together!
p
  | I'm using R to add 1+1. It's giving me back the answer:
  pre
    = @output

