require 'spec_helper'

describe "relevances/show.html.erb" do
  before(:each) do
    @relevance = assign(:relevance, stub_model(Relevance,
      :sig_class_id => "",
      :classification_id => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(//)
  end
end
