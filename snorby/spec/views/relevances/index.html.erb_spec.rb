require 'spec_helper'

describe "relevances/index.html.erb" do
  before(:each) do
    assign(:relevances, [
      stub_model(Relevance,
        :sig_class_id => "",
        :classification_id => ""
      ),
      stub_model(Relevance,
        :sig_class_id => "",
        :classification_id => ""
      )
    ])
  end

  it "renders a list of relevances" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
