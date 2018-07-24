# frozen_string_literal: true

module FontAwesomeVersionHelper
  # Determines if the App uses Font Awesome releases 3.x or 4.x
  # @return [TrueClass, FalseClass]
  def font_awesome_four?
    Bundler.environment.specs['font-awesome-rails'].first.version >= Gem::Version.new('4')
  end

  # Selects one of two HTML element classes depending upon the release of Font Awesome used by the App
  # @param if3 [String] the Font Awesome 3 HTML class
  # @param if4 [String] the Font Awesome 4 HTML class
  # @return [String] the Font Awesome HTML class
  def fa3or4(if3, if4)
    font_awesome_four? ? if4 : if3
  end
end
