require 'spec_helper'

describe RelevancesController do

  def mock_relevance(stubs={})
    (@mock_relevance ||= mock_model(Relevance).as_null_object).tap do |relevance|
      relevance.stub(stubs) unless stubs.empty?
    end
  end

  describe "GET index" do
    it "assigns all relevances as @relevances" do
      Relevance.stub(:all) { [mock_relevance] }
      get :index
      assigns(:relevances).should eq([mock_relevance])
    end
  end

  describe "GET show" do
    it "assigns the requested relevance as @relevance" do
      Relevance.stub(:get).with("37") { mock_relevance }
      get :show, :id => "37"
      assigns(:relevance).should be(mock_relevance)
    end
  end

  describe "GET new" do
    it "assigns a new relevance as @relevance" do
      Relevance.stub(:new) { mock_relevance }
      get :new
      assigns(:relevance).should be(mock_relevance)
    end
  end

  describe "GET edit" do
    it "assigns the requested relevance as @relevance" do
      Relevance.stub(:get).with("37") { mock_relevance }
      get :edit, :id => "37"
      assigns(:relevance).should be(mock_relevance)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created relevance as @relevance" do
        Relevance.stub(:new).with({'these' => 'params'}) { mock_relevance(:save => true) }
        post :create, :relevance => {'these' => 'params'}
        assigns(:relevance).should be(mock_relevance)
      end

      it "redirects to the created relevance" do
        Relevance.stub(:new) { mock_relevance(:save => true) }
        post :create, :relevance => {}
        response.should redirect_to(relevance_url(mock_relevance))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved relevance as @relevance" do
        Relevance.stub(:new).with({'these' => 'params'}) { mock_relevance(:save => false) }
        post :create, :relevance => {'these' => 'params'}
        assigns(:relevance).should be(mock_relevance)
      end

      it "re-renders the 'new' template" do
        Relevance.stub(:new) { mock_relevance(:save => false) }
        post :create, :relevance => {}
        response.should render_template("new")
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested relevance" do
        Relevance.should_receive(:get).with("37") { mock_relevance }
        mock_relevance.should_receive(:update).with({'these' => 'params'})
        put :update, :id => "37", :relevance => {'these' => 'params'}
      end

      it "assigns the requested relevance as @relevance" do
        Relevance.stub(:get) { mock_relevance(:update => true) }
        put :update, :id => "1"
        assigns(:relevance).should be(mock_relevance)
      end

      it "redirects to the relevance" do
        Relevance.stub(:get) { mock_relevance(:update => true) }
        put :update, :id => "1"
        response.should redirect_to(relevance_url(mock_relevance))
      end
    end

    describe "with invalid params" do
      it "assigns the relevance as @relevance" do
        Relevance.stub(:get) { mock_relevance(:update => false) }
        put :update, :id => "1"
        assigns(:relevance).should be(mock_relevance)
      end

      it "re-renders the 'edit' template" do
        Relevance.stub(:get) { mock_relevance(:update => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested relevance" do
      Relevance.should_receive(:get).with("37") { mock_relevance }
      mock_relevance.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the relevances list" do
      Relevance.stub(:get) { mock_relevance }
      delete :destroy, :id => "1"
      response.should redirect_to(relevances_url)
    end
  end

end
