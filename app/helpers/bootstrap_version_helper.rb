module BootstrapVersionHelper
  def bootstrap_three?
    Bundler.environment.specs['bootstrap-sass'].first.version >= Gem::Version.new('3')
  end

  def bs2(if2)
    bs2or3(if2, '')
  end

  def bs3(if3)
    bs2or3('', if3)
  end

  def bs2or3(if2, if3)
    bootstrap_three? ? if3 : if2
  end

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
