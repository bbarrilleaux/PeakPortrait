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
  if params[:file]
    puts params[:file]
    tempfile = params[:file][:tempfile]
    filename = params[:file][:filename]
    File.open("./tmp/input.txt", "w") { |f| f.write(tempfile.read) }
  else
      raise "You didn't select a file."
  end
 
  R.eval <<EOF
    getwd()
#   data <- rnorm(100, #{@chromosome_column})
    data <- read.table("./tmp/input.txt",sep="\t")
   png("./tmp/graph.png", type="cairo-png")
    hist(data[,2], main="Here's a demo graph.", xlab="Centered on the chromosome column you entered.")
   dev.off()
EOF

  if File.exists?("./tmp/input.txt")
    File.delete("./tmp/input.txt")
  end

  if File.exists?("./tmp/graph.png")
    @data_uri = Base64.strict_encode64(File.open("./tmp/graph.png", "rb").read)
    File.delete("./tmp/graph.png")
  end
  slim :graph
end