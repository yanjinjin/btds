require 'spec_helper'

describe "rules/new.html.erb" do
  before(:each) do
    assign(:rule, stub_model(Rule,
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
    ).as_new_record)
  end

  it "renders new rule form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => rules_path, :method => "post" do
      assert_select "input#rule_id", :name => "rule[id]"
      assert_select "input#rule_type1", :name => "rule[type1]"
      assert_select "input#rule_type2", :name => "rule[type2]"
      assert_select "input#rule_source", :name => "rule[source]"
      assert_select "input#rule_sourcep", :name => "rule[sourcep]"
      assert_select "input#rule_target", :name => "rule[target]"
      assert_select "input#rule_targetp", :name => "rule[targetp]"
      assert_select "input#rule_msg", :name => "rule[msg]"
      assert_select "input#rule_classtype", :name => "rule[classtype]"
      assert_select "input#rule_sid", :name => "rule[sid]"
    end
  end
end
