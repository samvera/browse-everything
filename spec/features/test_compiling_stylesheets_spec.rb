require 'spec_helper'

describe "Compiling the stylesheets", :type => :feature do
  it "should not raise errors" do
    visit '/'
    expect(page).not_to have_content 'Sass::SyntaxError'
  end
end
