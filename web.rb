require 'sinatra'
require 'slim'
require 'rinruby'
require 'pry' 
require 'base64'
require 'sass'

set :slim, :pretty => true
set :root, File.dirname(__FILE__)

class ChromosomeDataFile
  def initialize(params = {})
    @params = params
    @errors = []
  end

  attr_accessor :errors

  def valid?
    @errors << "Need to select a file to graph." unless @params[:file]
    @errors.empty?
  end

  def gff?
    @params[:file_type] == "GFF"
  end

  def start_column
    gff? ? 4 : 2
  end

  def end_column
    return 0 if @params[:use_peak_widths] == "no"
    gff? ? 5 : 3
  end

  def score_column
    if @params[:use_score] == "no"
      return 0
    elsif @params[:use_score] == "5 (BED/broadPeak)"
      return 5
    elsif @params[:use_score] == "6 (GFF)"
      return 6
    else
      return @params[:use_score].to_i
    end
  end

  def write_temp_file(file_path)
    temp_file = @params[:file][:tempfile]
    FileUtils.mkdir_p(File.dirname(file_path))
    dest_file = File.open(file_path, "w")
    file_contents = temp_file.read
    file_contents.gsub!(/\r\n?/, "\n") # make sure line endings are consistent
    file_contents.each_line do |line|
        # only keep lines that start with "chr". other lines are probably headers/comments/junk.
        dest_file.write(line) if /^chr/.match(line) 
    end
  end

  def delete_temp_file(file_path)
    File.delete(file_path)
  end
end

get '/styles.css' do
  scss :styles
end

get '/' do
  @data_file = ChromosomeDataFile.new 
  slim :index
end

post '/' do
  @data_file = ChromosomeDataFile.new params
  return slim :index unless @data_file.valid?
  R.start_column = @data_file.start_column
  R.end_column = @data_file.end_column
  R.score_column = @data_file.score_column
  temp_file_path = "./tmp/input.txt"
  R.file = temp_file_path
  @data_file.write_temp_file(temp_file_path)
 
  R.eval <<EOF
    library(ggplot2)
    library(gtools) # for reordering chromosome names
    source("./prepare_data.r")    
    data <- parsePeakFile(file, start_column, end_column, score_column)
    species <- checkSpecies(data)
    data <- rbind(data, fetchChromosomeLengths(species))
    data$Chromosome <- factor(data$Chromosome, mixedsort(levels(data$Chromosome)))
    theme_set(theme_gray(base_size = 18)) # make fonts bigger
    png("./tmp/graph.png", type="cairo-png", width = 900, height=600)
      hist_results <- ggplot(data, aes(x = loc/1000000, colour = Chromosome, weight = size))
      hist_results + geom_freqpoly() + 
        xlab("Position along chromosome (Mbp)") + ylab("Intensity") +
        facet_wrap("Chromosome", drop = FALSE, scales = "free_x")
   dev.off()
EOF
  @species = R.species
  @data_file.delete_temp_file(temp_file_path)
  if File.exists?("./tmp/graph.png")
    @data_uri = Base64.strict_encode64(File.open("./tmp/graph.png", "rb").read)
    File.delete("./tmp/graph.png")
  end
  slim :graph 
end

get '/help' do
  slim :help
end