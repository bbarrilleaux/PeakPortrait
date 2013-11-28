require 'sinatra'
require 'slim'
require 'rinruby'
require 'pry' 
require 'base64'
require 'sass'

set :slim, :pretty => true
set :root, File.dirname(__FILE__)


get '/styles.css' do
  scss :styles
end

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
    raise "You didn't select a file?"
  end
 
  R.eval <<EOF
    library(ggplot2)
    library(gtools) #for reordering chromosome names
    getwd()
    data <- read.table("./tmp/input.txt",sep="\t",header=TRUE)
    data <- data.frame(data[,1], data[,#{@start_column}])
    names(data) <- c("Chromosome", "loc")
    data$Chromosome <- factor(data$Chromosome, mixedsort(levels(data$Chromosome)))
    theme_set(theme_gray(base_size = 18)) #make fonts bigger
    png("./tmp/graph.png", type="cairo-png", width = 1000, height=500)
      hist_results <- ggplot(data, aes(x=loc/1000000, colour=Chromosome))
      hist_results + geom_freqpoly() + 
        xlab("Relative distance from centromere (Mbp)") +
        facet_wrap("Chromosome", drop=FALSE, scales="free_x")
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