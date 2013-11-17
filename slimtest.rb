require 'thin'
require 'sinatra'
require 'slim'

set :slim, :pretty => true

get '/' do
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
