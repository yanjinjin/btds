require "spec_helper"

describe TcpdumpsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/tcpdumps" }.should route_to(:controller => "tcpdumps", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/tcpdumps/new" }.should route_to(:controller => "tcpdumps", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/tcpdumps/1" }.should route_to(:controller => "tcpdumps", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/tcpdumps/1/edit" }.should route_to(:controller => "tcpdumps", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/tcpdumps" }.should route_to(:controller => "tcpdumps", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/tcpdumps/1" }.should route_to(:controller => "tcpdumps", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/tcpdumps/1" }.should route_to(:controller => "tcpdumps", :action => "destroy", :id => "1")
    end

  end
end
