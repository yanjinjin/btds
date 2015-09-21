require "spec_helper"

describe RelevancesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/relevances" }.should route_to(:controller => "relevances", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/relevances/new" }.should route_to(:controller => "relevances", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/relevances/1" }.should route_to(:controller => "relevances", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/relevances/1/edit" }.should route_to(:controller => "relevances", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/relevances" }.should route_to(:controller => "relevances", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/relevances/1" }.should route_to(:controller => "relevances", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/relevances/1" }.should route_to(:controller => "relevances", :action => "destroy", :id => "1")
    end

  end
end
