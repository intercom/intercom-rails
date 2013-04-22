require 'test_setup'

class MethodCatcherTest < MiniTest::Unit::TestCase 
  
  include IntercomRails
  include InterTest

  def test_catches_methods
    method_catcher = Util::MethodCatcher.new
    method_catcher.hey
    method_catcher.there
    assert_equal [:hey, :there], method_catcher.methods_called
  end

  def test_knows_union_of_methods_called_and_an_array_of_method_names
    method_catcher = Util::MethodCatcher.new
    method_catcher.hey
    method_catcher.there

    assert_equal [:hey], (method_catcher & [:hey])
  end

end
