require 'spec_helper'

describe "logs/index.html.erb" do
  before(:each) do
    assign(:logs, [
      stub_model(Log,
        :ip => "Ip",
        :username => "Username",
        :opobject => "Opobject",
        :opdetail => "Opdetail"
      ),
      stub_model(Log,
        :ip => "Ip",
        :username => "Username",
        :opobject => "Opobject",
        :opdetail => "Opdetail"
      )
    ])
  end

  it "renders a list of logs" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ip".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Username".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Opobject".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Opdetail".to_s, :count => 2
  end
end
