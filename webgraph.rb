require 'sinatra'
require 'slim'
require 'rinruby'
require 'pry' 
require 'base64'

set :slim, :pretty => true


get '/' do
  slim :index
end


post '/' do
  input = params[:input]
  R.eval <<EOF
   data <- rnorm(100, #{input})
   png("stuff.png")
    hist(data)
   dev.off()
EOF
  data_uri = Base64.strict_encode64(File.open("stuff.png", "rb").read)
  image_tag = '<img alt="sample" src="data:image/png;base64,%s">' % data_uri
  html = "<html>"
  html += "<head><title>Here's your graph</title></head>"
  html += "<body>"
  html += image_tag

#  slim :task
end