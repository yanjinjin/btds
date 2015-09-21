require 'spec_helper'

describe "logs/edit.html.erb" do
  before(:each) do
    @log = assign(:log, stub_model(Log,
      :new_record? => false,
      :ip => "MyString",
      :username => "MyString",
      :opobject => "MyString",
      :opdetail => "MyString"
    ))
  end

  it "renders the edit log form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => log_path(@log), :method => "post" do
      assert_select "input#log_ip", :name => "log[ip]"
      assert_select "input#log_username", :name => "log[username]"
      assert_select "input#log_opobject", :name => "log[opobject]"
      assert_select "input#log_opdetail", :name => "log[opdetail]"
    end
  end
end
