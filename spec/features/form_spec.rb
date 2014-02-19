feature "feeding it bad data" do
	scenario "rejects a non-text file" do
	  visit "/"
	  attach_file "fileInput", "./spec/testdata/NotATextFile.jpg"
	  click_button "Generate portrait"
	  expect(page).to have_content 'must be tab-delimited text'
	end

	scenario "complains about data with more than 50 chromosomes" do
	  visit "/"
	  attach_file "fileInput", "./spec/testdata/TooManyChr.bed"
	  click_button "Generate portrait"
	  expect(page).to have_content 'more than 50 different chromosome names'
	end


end

feature "making a graph" do
	scenario "can auto-detect human data" do
	  visit "/"
	  attach_file "fileInput", "./spec/testdata/HumanDataWithInconsistentCaps.bed"
	  click_button "Generate portrait"
	  expect(page).to have_content 'Species: human'
	  expect(page).to have_content 'graph was created successfully'
	end

	scenario "can auto-detect mouse data" do
	  visit "/"
	  attach_file "fileInput", "./spec/testdata/SparseMouseDataWithScores.bed"
	  click_button "Generate portrait"
	  expect(page).to have_content 'Species: mouse'
	  expect(page).to have_content 'graph was created successfully'
	end

	scenario "can handle unknown species data" do
	  visit "/"
	  attach_file "fileInput", "./spec/testdata/UnknownSpecies.bed"
	  click_button "Generate portrait"
	  expect(page).to have_content 'Species: unknown'
	  expect(page).to have_content 'graph was created successfully'
	end

	scenario "can graph a GFF file" do
	  visit "/"
	  attach_file "fileInput", "./spec/testdata/BigGFFFileWithCommentLine.gff"
	  page.choose("GFF")
	  click_button "Generate portrait"
	  expect(page).to have_content 'graph was created successfully'
	end

end