require_relative '../spec_helper'

feature 'Home' do
  scenario 'responds with successful status' do
    visit '/'
    expect(page.status_code).to eq(200)
  end

end