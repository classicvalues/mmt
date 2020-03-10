require 'rails_helper'

describe 'Service Organizations Form', js: true do
  before do
    login
    draft = create(:empty_service_draft, user: User.where(urs_uid: 'testuser').first)
    visit edit_service_draft_path(draft, 'service_organizations')
  end

  context 'when submitting the form' do
    before do
      puts ">>>>>>>>>>>>>>>>>>>>>>>>>>"
      puts "Before add_service_organizations: #{Time.now.strftime("%k:%M:%S")}"
      add_service_organizations
      puts "<<<<<<<<<<<<<<<<<<<<<<<<<<"
      puts "After add_service_organizations #{Time.now.strftime("%k:%M:%S")}"

      within '.nav-top' do
        click_on 'Save'
      end
    end

    it 'displays a confirmation message' do
      expect(page).to have_content('Service Draft Updated Successfully!')
    end

    context 'when viewing the form' do
      include_examples 'Service Organizations Form'
    end
  end
end
