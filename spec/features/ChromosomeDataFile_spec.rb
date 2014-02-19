describe ChromosomeDataFile do
  describe '#gff?' do
    it 'defaults to false' do
    	expect(ChromosomeDataFile.new.gff?).to be_false
    end
    it 'returns true when the file type is set as GFF' do
    	params = {:file_type => "GFF"}
    	data_file = ChromosomeDataFile.new params
    	expect(data_file.gff?).to be_true
    end
  end

  describe '#start_column' do
  	it 'defaults to 2' do
  		expect(ChromosomeDataFile.new.start_column).to eq(2)
  	end
  end

  describe '#end_column' do
  	it 'defaults to 0' do
  		expect(ChromosomeDataFile.new.end_column).to eq(0)
  	end
  end

  describe '#score_column' do
  	it 'returns 0 when use_score is not selected' do
  		params = {:use_score => FALSE}
  		data_file = ChromosomeDataFile.new params
  		expect(data_file.score_column). to eq(0)
  	end
  	it 'returns the number in score_column when use_score is selected and score_column is > 0' do
  		params = {:use_score => TRUE, :score_column => "3"}
  		data_file = ChromosomeDataFile.new params
  		expect(data_file.score_column). to eq(3)
  	end
  	it 'returns default of 5 for BED files when use_score is selected and score_column is 0' do
  		params = {:use_score => TRUE, :score_column => "0"}
  		data_file = ChromosomeDataFile.new params
  		expect(data_file.score_column). to eq(5)
  	end  	
  	it 'returns default of 6 for GFF files when use_score is selected and score_column is 0 and file type is GFF' do
  		params = {:use_score => TRUE, :score_column => "0", :file_type => "GFF"}
  		data_file = ChromosomeDataFile.new params
  		expect(data_file.score_column). to eq(6)
  	end  	
  end

  describe '#valid?' do
  	it 'is not valid before a file is selected' do
  		data_file = ChromosomeDataFile.new
  		expect(data_file.valid?).to be_false
  	end
  	it 'sets a no-file error when no file has been selected' do
  		data_file = ChromosomeDataFile.new
  		data_file.valid?
  		expect(data_file.errors).to include("Need to select a file to graph.")
  	end
  	it 'returns true if params hash includes a file' do
	  	params = {:file => "file"}
	  	data_file = ChromosomeDataFile.new params
	  	expect(data_file.valid?).to be_true
  	end
  end

end