module FontAwesomeVersionHelper
  def font_awesome_four?
    Bundler.environment.specs['font-awesome-rails'].first.version >= Gem::Version.new('4')
  end

  def fa3(if3)
    fa3or4(if3, '')
  end

  def fa4(if4)
    fa3or4('', if4)
  end

  def fa3or4(if3, if4)
    font_awesome_four? ? if4 : if3
  end
end
