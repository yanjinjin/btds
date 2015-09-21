require 'spec_helper'

describe "rules/index.html.erb" do
  before(:each) do
    assign(:rules, [
      stub_model(Rule,
        :id => "",
        :type1 => "",
        :type2 => "",
        :source => "",
        :sourcep => "",
        :target => "",
        :targetp => "",
        :msg => "",
        :classtype => "",
        :sid => ""
      ),
      stub_model(Rule,
        :id => "",
        :type1 => "",
        :type2 => "",
        :source => "",
        :sourcep => "",
        :target => "",
        :targetp => "",
        :msg => "",
        :classtype => "",
        :sid => ""
      )
    ])
  end

  it "renders a list of rules" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
