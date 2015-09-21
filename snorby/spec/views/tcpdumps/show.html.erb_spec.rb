require 'spec_helper'

describe "tcpdumps/show.html.erb" do
  before(:each) do
    @tcpdump = assign(:tcpdump, stub_model(Tcpdump,
      :id => 1,
      :status => "",
      :name => "Name",
      :src_ip => "Src Ip",
      :dst_ip => "Dst Ip",
      :src_port => "Src Port",
      :dst_port => "Dst Port",
      :protocol => "Protocol",
      :plan_size => "Plan Size",
      :plan_task => "Plan Task"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Name/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Src Ip/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Dst Ip/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Src Port/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Dst Port/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Protocol/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Plan Size/)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(/Plan Task/)
  end
end
