class PositiveOperatorMatcher
  def initialize(actual)
    @actual = actual
  end
  
  def ==(expected)
    unless @actual == expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "to equal #{expected.pretty_inspect}")
    end
  end
  
  def <(expected)
    unless @actual < expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "to be less than #{expected.pretty_inspect}")
    end
  end

  def <=(expected)
    unless @actual <= expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "to be less than or equal to #{expected.pretty_inspect}")
    end
  end

  def >(expected)
    unless @actual > expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "to be greater than #{expected.pretty_inspect}")
    end
  end
  
  def >=(expected)
    unless @actual >= expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "to be greater than or equal to #{expected.pretty_inspect}")
    end
  end
  
  def =~(expected)
    unless @actual =~ expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "to match #{expected.pretty_inspect}")
    end
  end
end

class NegativeOperatorMatcher
  def initialize(actual)
    @actual = actual
  end
  
  def ==(expected)
    if @actual == expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "not to equal #{expected.pretty_inspect}")
    end
  end
  
  def <(expected)
    if @actual < expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}", 
                            "not to be less than #{expected.pretty_inspect}")
    end
  end
  
  def <=(expected)
    if @actual <= expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}", 
                            "not to be less than or equal to #{expected.pretty_inspect}")
    end
  end
  
  def >(expected)
    if @actual > expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}", 
                            "not to be greater than #{expected.pretty_inspect}")
    end
  end
  
  def >=(expected)
    if @actual >= expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}", 
                            "not to be greater than or equal to #{expected.pretty_inspect}")
    end
  end
  
  def =~(expected)
    if @actual =~ expected
      Expectation.fail_with("Expected #{@actual.pretty_inspect}",
                            "not to match #{expected.pretty_inspect}")
    end
  end
end
