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
    R.start_column = 4
    R.end_column = 5
  else
    R.start_column = 2
    R.end_column = 3
  end

  if params[:use_peak_widths] == "no"
    R.end_column = 0
  end

  if params[:use_score] == "no"
    R.score_column = 0
  elsif params[:use_score] == "5 (BED/broadPeak)"
    R.score_column = 5
  elsif params[:use_score] == "6 (GFF)"
    R.score_column = 6
  else
    R.score_column = params[:use_score].to_i
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
    
    peakfile <- read.table("./tmp/input.txt",sep="\t",header=TRUE)
    data <- data.frame(peakfile[,1], peakfile[,start_column])
    if(end_column && !score_column) { 
      data <- cbind(data, peakfile[,end_column] - peakfile[,start_column]) 
    } else if (!end_column && score_column) {
      data <- cbind(data, peakfile[,score_column])
    } else if (end_column && score_column) {
      data <- cbind(data, (peakfile[,end_column] - peakfile[,start_column]) * peakfile[,score_column] )
    } else {
      data <- cbind(data, rep(1,nrow(data)))
    }
    names(data) <- c("Chromosome", "loc", "size")
    data$Chromosome <- factor(data$Chromosome, mixedsort(levels(data$Chromosome)))
    theme_set(theme_gray(base_size = 18)) #make fonts bigger

    png("./tmp/graph.png", type="cairo-png", width = 900, height=600)
      hist_results <- ggplot(data, aes(x=loc/1000000, colour=Chromosome, weight=size))
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