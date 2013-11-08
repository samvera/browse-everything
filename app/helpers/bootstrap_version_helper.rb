module BootstrapVersionHelper

  def bootstrap_three?
    Bundler.environment.specs['bootstrap-sass'].first.version >= Gem::Version.new('3')
  end

  def bs2(if2)
    bs2or3(if2,'')
  end

  def bs3(if3)
    bs2or3('',if3)
  end

  def bs2or3(if2,if3)
    bootstrap_three? ? if3 : if2
  end

end