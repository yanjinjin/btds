require 'spec_helper'

describe LogsController do

  def mock_log(stubs={})
    (@mock_log ||= mock_model(Log).as_null_object).tap do |log|
      log.stub(stubs) unless stubs.empty?
    end
  end

  describe "GET index" do
    it "assigns all logs as @logs" do
      Log.stub(:all) { [mock_log] }
      get :index
      assigns(:logs).should eq([mock_log])
    end
  end

  describe "GET show" do
    it "assigns the requested log as @log" do
      Log.stub(:get).with("37") { mock_log }
      get :show, :id => "37"
      assigns(:log).should be(mock_log)
    end
  end

  describe "GET new" do
    it "assigns a new log as @log" do
      Log.stub(:new) { mock_log }
      get :new
      assigns(:log).should be(mock_log)
    end
  end

  describe "GET edit" do
    it "assigns the requested log as @log" do
      Log.stub(:get).with("37") { mock_log }
      get :edit, :id => "37"
      assigns(:log).should be(mock_log)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created log as @log" do
        Log.stub(:new).with({'these' => 'params'}) { mock_log(:save => true) }
        post :create, :log => {'these' => 'params'}
        assigns(:log).should be(mock_log)
      end

      it "redirects to the created log" do
        Log.stub(:new) { mock_log(:save => true) }
        post :create, :log => {}
        response.should redirect_to(log_url(mock_log))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved log as @log" do
        Log.stub(:new).with({'these' => 'params'}) { mock_log(:save => false) }
        post :create, :log => {'these' => 'params'}
        assigns(:log).should be(mock_log)
      end

      it "re-renders the 'new' template" do
        Log.stub(:new) { mock_log(:save => false) }
        post :create, :log => {}
        response.should render_template("new")
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested log" do
        Log.should_receive(:get).with("37") { mock_log }
        mock_log.should_receive(:update).with({'these' => 'params'})
        put :update, :id => "37", :log => {'these' => 'params'}
      end

      it "assigns the requested log as @log" do
        Log.stub(:get) { mock_log(:update => true) }
        put :update, :id => "1"
        assigns(:log).should be(mock_log)
      end

      it "redirects to the log" do
        Log.stub(:get) { mock_log(:update => true) }
        put :update, :id => "1"
        response.should redirect_to(log_url(mock_log))
      end
    end

    describe "with invalid params" do
      it "assigns the log as @log" do
        Log.stub(:get) { mock_log(:update => false) }
        put :update, :id => "1"
        assigns(:log).should be(mock_log)
      end

      it "re-renders the 'edit' template" do
        Log.stub(:get) { mock_log(:update => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested log" do
      Log.should_receive(:get).with("37") { mock_log }
      mock_log.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the logs list" do
      Log.stub(:get) { mock_log }
      delete :destroy, :id => "1"
      response.should redirect_to(logs_url)
    end
  end

end
