require 'spec_helper'

describe "logs/new.html.erb" do
  before(:each) do
    assign(:log, stub_model(Log,
      :ip => "MyString",
      :username => "MyString",
      :opobject => "MyString",
      :opdetail => "MyString"
    ).as_new_record)
  end

  it "renders new log form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => logs_path, :method => "post" do
      assert_select "input#log_ip", :name => "log[ip]"
      assert_select "input#log_username", :name => "log[username]"
      assert_select "input#log_opobject", :name => "log[opobject]"
      assert_select "input#log_opdetail", :name => "log[opdetail]"
    end
  end
end
