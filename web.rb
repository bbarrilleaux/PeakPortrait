require 'sinatra'
require 'slim'
require 'rinruby'
require 'pry' 
require 'base64'

set :slim, :pretty => true
set :root, File.dirname(__FILE__)

get '/' do
  slim :index
end

post '/' do
  path="./tmp"
  FileUtils.mkdir(path) unless File.exists?(path)

  @start_column = params[:start_column]
  @chromosome_column = params[:chromosome_column]
  puts @chromosome_column
  puts @start_column
  R.eval <<EOF
   data <- rnorm(100, #{@chromosome_column})
   png("./tmp/graph.png", type="cairo-png")
    hist(data, main="Here's a demo graph.", xlab="Centered on the chromosome column you entered.")
   dev.off()
EOF
  @data_uri = Base64.strict_encode64(File.open("./tmp/graph.png", "rb").read)

 File.delete("./tmp/graph.png")
  slim :graph
end