require 'spec_helper'

describe "relevances/new.html.erb" do
  before(:each) do
    assign(:relevance, stub_model(Relevance,
      :sig_class_id => "",
      :classification_id => ""
    ).as_new_record)
  end

  it "renders new relevance form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => relevances_path, :method => "post" do
      assert_select "input#relevance_sig_class_id", :name => "relevance[sig_class_id]"
      assert_select "input#relevance_classification_id", :name => "relevance[classification_id]"
    end
  end
end
