require 'spec_helper'

describe "tcpdumps/index.html.erb" do
  before(:each) do
    assign(:tcpdumps, [
      stub_model(Tcpdump,
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
      ),
      stub_model(Tcpdump,
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
      )
    ])
  end

  it "renders a list of tcpdumps" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Src Ip".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Dst Ip".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Src Port".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Dst Port".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Protocol".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Plan Size".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Plan Task".to_s, :count => 2
  end
end
