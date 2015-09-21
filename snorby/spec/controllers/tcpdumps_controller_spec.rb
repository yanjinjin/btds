require 'spec_helper'

describe TcpdumpsController do

  def mock_tcpdump(stubs={})
    (@mock_tcpdump ||= mock_model(Tcpdump).as_null_object).tap do |tcpdump|
      tcpdump.stub(stubs) unless stubs.empty?
    end
  end

  describe "GET index" do
    it "assigns all tcpdumps as @tcpdumps" do
      Tcpdump.stub(:all) { [mock_tcpdump] }
      get :index
      assigns(:tcpdumps).should eq([mock_tcpdump])
    end
  end

  describe "GET show" do
    it "assigns the requested tcpdump as @tcpdump" do
      Tcpdump.stub(:get).with("37") { mock_tcpdump }
      get :show, :id => "37"
      assigns(:tcpdump).should be(mock_tcpdump)
    end
  end

  describe "GET new" do
    it "assigns a new tcpdump as @tcpdump" do
      Tcpdump.stub(:new) { mock_tcpdump }
      get :new
      assigns(:tcpdump).should be(mock_tcpdump)
    end
  end

  describe "GET edit" do
    it "assigns the requested tcpdump as @tcpdump" do
      Tcpdump.stub(:get).with("37") { mock_tcpdump }
      get :edit, :id => "37"
      assigns(:tcpdump).should be(mock_tcpdump)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created tcpdump as @tcpdump" do
        Tcpdump.stub(:new).with({'these' => 'params'}) { mock_tcpdump(:save => true) }
        post :create, :tcpdump => {'these' => 'params'}
        assigns(:tcpdump).should be(mock_tcpdump)
      end

      it "redirects to the created tcpdump" do
        Tcpdump.stub(:new) { mock_tcpdump(:save => true) }
        post :create, :tcpdump => {}
        response.should redirect_to(tcpdump_url(mock_tcpdump))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved tcpdump as @tcpdump" do
        Tcpdump.stub(:new).with({'these' => 'params'}) { mock_tcpdump(:save => false) }
        post :create, :tcpdump => {'these' => 'params'}
        assigns(:tcpdump).should be(mock_tcpdump)
      end

      it "re-renders the 'new' template" do
        Tcpdump.stub(:new) { mock_tcpdump(:save => false) }
        post :create, :tcpdump => {}
        response.should render_template("new")
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested tcpdump" do
        Tcpdump.should_receive(:get).with("37") { mock_tcpdump }
        mock_tcpdump.should_receive(:update).with({'these' => 'params'})
        put :update, :id => "37", :tcpdump => {'these' => 'params'}
      end

      it "assigns the requested tcpdump as @tcpdump" do
        Tcpdump.stub(:get) { mock_tcpdump(:update => true) }
        put :update, :id => "1"
        assigns(:tcpdump).should be(mock_tcpdump)
      end

      it "redirects to the tcpdump" do
        Tcpdump.stub(:get) { mock_tcpdump(:update => true) }
        put :update, :id => "1"
        response.should redirect_to(tcpdump_url(mock_tcpdump))
      end
    end

    describe "with invalid params" do
      it "assigns the tcpdump as @tcpdump" do
        Tcpdump.stub(:get) { mock_tcpdump(:update => false) }
        put :update, :id => "1"
        assigns(:tcpdump).should be(mock_tcpdump)
      end

      it "re-renders the 'edit' template" do
        Tcpdump.stub(:get) { mock_tcpdump(:update => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested tcpdump" do
      Tcpdump.should_receive(:get).with("37") { mock_tcpdump }
      mock_tcpdump.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the tcpdumps list" do
      Tcpdump.stub(:get) { mock_tcpdump }
      delete :destroy, :id => "1"
      response.should redirect_to(tcpdumps_url)
    end
  end

end
