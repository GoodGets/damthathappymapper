require File.dirname(__FILE__) + '/spec_helper.rb'

describe HappyMapper::Attribute do
  describe "initialization" do
    before do
      @attr = HappyMapper::TextNode.new(:foo, String)
    end
    
    it 'should know that it is a text node' do
      @attr.text_node?.should be_true
    end
    
    it 'should know that it is NOT an element' do
      @attr.element?.should be_false
    end

    it 'should know that it is NOT an attribute' do
      @attr.attribute?.should be_false
    end
  end
end
