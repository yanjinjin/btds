require 'spec_helper'

describe "relevances/edit.html.erb" do
  before(:each) do
    @relevance = assign(:relevance, stub_model(Relevance,
      :new_record? => false,
      :sig_class_id => "",
      :classification_id => ""
    ))
  end

  it "renders the edit relevance form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => relevance_path(@relevance), :method => "post" do
      assert_select "input#relevance_sig_class_id", :name => "relevance[sig_class_id]"
      assert_select "input#relevance_classification_id", :name => "relevance[classification_id]"
    end
  end
end
