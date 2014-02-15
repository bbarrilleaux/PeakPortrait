require 'sinatra'
require 'slim'
require 'rinruby'
require 'pry' 
require 'base64'
require 'sass'
require 'coffee_script'
require 'bootstrap-sass'
require 'sinatra/base'
require 'sinatra/assetpack'

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
    return 0 unless @params[:use_peak_widths]
    gff? ? 5 : 3
  end

  def score_column
    if @params[:score_column] != ""
      return @params[:score_column].to_i
    elsif @params[:use_score]
      return gff? ? 6 : 5
    else 
      return 0
    end
  end

  def trap_r_errors
      @errors << "Failed to parse file. It must be tab-delimited text."
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


class PeakPortrait < Sinatra::Base

  register Sinatra::AssetPack
  
  set :slim, :pretty => true
  set :root, File.dirname(__FILE__)

  assets do
    serve '/js',     from: 'public/js'       
    serve '/css',    from: 'public/css'       
    serve '/image', from: 'public/fonts'

    js :application, ['/js/*.js']
    css :application, ['/css/*.css']

    js_compression  :jsmin   
    css_compression :sass  
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
   
#   print "start col = %d" % @data_file.start_column
#    print "end col = %d" % @data_file.end_column
#    print "score col = %d" % @data_file.score_column

    R.eval <<EOF
      library(ggplot2)
      library(gtools) # for reordering chromosome names
      source("./R/prepare_data.r")   
      gdata <- FALSE
      errors <- 2
      tryCatch({
        gdata <- parsePeakFile(file, start_column, end_column, score_column)
        species <- checkSpecies(gdata)
        gdata <- rbind(gdata, fetchChromosomeLengths(species))
        centromeres <- fetchCentromeres(species)
        gdata$Chromosome <- factor(gdata$Chromosome, mixedsort(levels(gdata$Chromosome)))

        theme_set(theme_gray(base_size = 18)) # make fonts bigger
        png("./tmp/graph.png", type="cairo-png", width = 900, height=600)
          hist_results <- ggplot(gdata, aes(x = loc/1000000, weight = size))
          hist_results <- hist_results + geom_freqpoly(size = 1.2) + 
            xlab("Position along chromosome (Mbp)") + ylab("Intensity") 
          if (species == "human") { hist_results <- hist_results + geom_vline(aes(xintercept = start/1000000), data = centromeres) }

          hist_results <- hist_results + facet_wrap(~ Chromosome, drop = FALSE, scales = "free_x")
          suppressMessages(print(hist_results))
        dev.off()
        errors <<- as.integer(0)
      }, error = function(e) errors <<- 1)      
EOF

#    print "r errors #{R.errors}"
    @data_file.delete_temp_file(temp_file_path)
    @data_uri = nil
    
    @data_file.trap_r_errors unless R.errors == 0
    return slim :index unless @data_file.valid?

    if File.exists?("./tmp/graph.png")
      @species = R.species
      @data_uri = Base64.strict_encode64(File.open("./tmp/graph.png", "rb").read)
      File.delete("./tmp/graph.png")
    end

    slim :graph 
  end

  get '/help' do
    slim :help
  end

  get '/sample' do
    slim :sample
  end

  # start the server if ruby file executed directly
  run! if app_file == $0

end