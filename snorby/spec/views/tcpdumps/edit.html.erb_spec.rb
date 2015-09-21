require 'spec_helper'

describe "tcpdumps/edit.html.erb" do
  before(:each) do
    @tcpdump = assign(:tcpdump, stub_model(Tcpdump,
      :new_record? => false,
      :id => 1,
      :status => "",
      :name => "MyString",
      :src_ip => "MyString",
      :dst_ip => "MyString",
      :src_port => "MyString",
      :dst_port => "MyString",
      :protocol => "MyString",
      :plan_size => "MyString",
      :plan_task => "MyString"
    ))
  end

  it "renders the edit tcpdump form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => tcpdump_path(@tcpdump), :method => "post" do
      assert_select "input#tcpdump_id", :name => "tcpdump[id]"
      assert_select "input#tcpdump_status", :name => "tcpdump[status]"
      assert_select "input#tcpdump_name", :name => "tcpdump[name]"
      assert_select "input#tcpdump_src_ip", :name => "tcpdump[src_ip]"
      assert_select "input#tcpdump_dst_ip", :name => "tcpdump[dst_ip]"
      assert_select "input#tcpdump_src_port", :name => "tcpdump[src_port]"
      assert_select "input#tcpdump_dst_port", :name => "tcpdump[dst_port]"
      assert_select "input#tcpdump_protocol", :name => "tcpdump[protocol]"
      assert_select "input#tcpdump_plan_size", :name => "tcpdump[plan_size]"
      assert_select "input#tcpdump_plan_task", :name => "tcpdump[plan_task]"
    end
  end
end
