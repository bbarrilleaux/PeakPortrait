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

  if params[:file_type] == "GFF"
    @start_column = 4
    @end_column = 5
    @score_column = 6
  else
    @start_column = 2
    @end_column = 3
    @score_column = 5
  end

  if params[:use_peak_widths] == "no"
    @end_column = nil
  end

  if params[:use_score] == "no"
    @score_column = nil
  end

  if params[:file]
    puts params[:file]
    tempfile = params[:file][:tempfile]
    filename = params[:file][:filename]
    File.open("./tmp/input.txt", "w") { |f| f.write(tempfile.read) }
  else
      raise "You didn't select a file."
  end
 
  R.eval <<EOF
    library(ggplot2)
    getwd()
    data <- read.table("./tmp/input.txt",sep="\t")
   png("./tmp/graph.png", type="cairo-png")
    qplot(data[, #{@start_column}], main="Here's a demo graph.", xlab="Centered on the chromosome column you entered.")
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

get '/help' do
  slim :help
end