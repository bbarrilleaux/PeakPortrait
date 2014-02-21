feature "form with bad data" do

	scenario "rejects a non-text file" do
		visit "/"
		attach_file "fileInput", "./spec/fixtures/NotATextFile.jpg"
		click_button "Generate portrait"
		expect(page).to have_content 'must be tab-delimited text'
	end

	scenario "rejects data with more than 50 chromosomes" do
		visit "/"
		attach_file "fileInput", "./spec/fixtures/TooManyChr.bed"
		click_button "Generate portrait"
		expect(page).to have_content 'more than 50 different chromosome names'
	end

	scenario "provides a suggestion if R parses the file but can't graph it", :js => true do
		visit "/"
 		page.check("use_score")
		attach_file "fileInput", "./spec/fixtures/SparseMouseDataWithScores.bed"
		click_button "Generate portrait"
		expect(page).to have_content 'supposed to be numeric contains something other than numbers'
	end

end

feature "form with good data" do
	scenario "auto-detects human data" do
		visit "/"
		attach_file "fileInput", "./spec/fixtures/HumanDataWithInconsistentCaps.bed"
		click_button "Generate portrait"
		expect(page).to have_content 'Species: human'
		expect(page).to have_content 'graph was created successfully'
	end

	scenario "auto-detects mouse data" do
		visit "/"
		attach_file "fileInput", "./spec/fixtures/SparseMouseDataWithScores.bed"
		click_button "Generate portrait"
		expect(page).to have_content 'Species: mouse'
		expect(page).to have_content 'graph was created successfully'
	end

	scenario "handles unknown species data" do
		visit "/"
		attach_file "fileInput", "./spec/fixtures/UnknownSpecies.bed"
		click_button "Generate portrait"
		expect(page).to have_content 'Species: unknown'
		expect(page).to have_content 'graph was created successfully'
	end

	scenario "graphs a GFF file" do
		visit "/"
		attach_file "fileInput", "./spec/fixtures/BigGFFFileWithCommentLine.gff"
		page.choose("GFF")
		click_button "Generate portrait"
		expect(page).to have_content 'graph was created successfully'
	end

end