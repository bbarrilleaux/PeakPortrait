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
    return 0 unless @params[:use_score]
    if @params[:score_column] == "0"
      return gff? ? 6 : 5
    else
      return @params[:score_column].to_i
    end
  end

  def species
    return @params[:species]
  end

  def write_temp_file(file_path)
    temp_file = @params[:file][:tempfile]
    FileUtils.mkdir_p(File.dirname(file_path))
    File.open(file_path, "w") do |dest_file|
      file_contents = temp_file.read
      file_contents.gsub!(/\r\n?/, "\n") # make sure line endings are consistent
      file_contents.each_line do |line|
          # only keep lines that start with "chr" or "Chr". other lines are probably headers/comments/junk.
          dest_file.write(line) if /^[Cc]hr/.match(line) 
      end
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

    r = RinRuby.new(:echo => false) 
    r.start_column = @data_file.start_column
    r.end_column = @data_file.end_column
    r.score_column = @data_file.score_column
    r.species = @data_file.species
    temp_file_path = "./tmp/input.txt"
    r.file = temp_file_path
    @data_file.write_temp_file(temp_file_path)
   
    r.eval 'source("./R/peakportrait.r")' 

    @data_file.delete_temp_file(temp_file_path)
    @data_uri = nil
    
    @data_file.errors << r.errors unless r.errors == 0

    if File.exists?("./tmp/graph.png")
      @species = r.species
      @data_uri = Base64.strict_encode64(File.open("./tmp/graph.png", "rb").read)
      File.delete("./tmp/graph.png")
    elsif @data_file.valid? 
      @data_file.errors << "Failed to generate a graph for unknown reasons. Check the data file: perhaps a column that's supposed to be numeric contains something other than numbers."
    end

    return slim :index unless @data_file.valid?

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