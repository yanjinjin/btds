require 'spec_helper'

describe "logs/show.html.erb" do
  before(:each) do
    @log = assign(:log, stub_model(Log,
      :ip => "Ip",
      :username => "Username",
      :opobject => "Opobject",
      :opdetail => "Opdetail"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Ip/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Username/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Opobject/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Opdetail/)
  end
end
