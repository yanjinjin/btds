require 'spec_helper'

describe RulesController do

  def mock_rule(stubs={})
    (@mock_rule ||= mock_model(Rule).as_null_object).tap do |rule|
      rule.stub(stubs) unless stubs.empty?
    end
  end

  describe "GET index" do
    it "assigns all rules as @rules" do
      Rule.stub(:all) { [mock_rule] }
      get :index
      assigns(:rules).should eq([mock_rule])
    end
  end

  describe "GET show" do
    it "assigns the requested rule as @rule" do
      Rule.stub(:get).with("37") { mock_rule }
      get :show, :id => "37"
      assigns(:rule).should be(mock_rule)
    end
  end

  describe "GET new" do
    it "assigns a new rule as @rule" do
      Rule.stub(:new) { mock_rule }
      get :new
      assigns(:rule).should be(mock_rule)
    end
  end

  describe "GET edit" do
    it "assigns the requested rule as @rule" do
      Rule.stub(:get).with("37") { mock_rule }
      get :edit, :id => "37"
      assigns(:rule).should be(mock_rule)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created rule as @rule" do
        Rule.stub(:new).with({'these' => 'params'}) { mock_rule(:save => true) }
        post :create, :rule => {'these' => 'params'}
        assigns(:rule).should be(mock_rule)
      end

      it "redirects to the created rule" do
        Rule.stub(:new) { mock_rule(:save => true) }
        post :create, :rule => {}
        response.should redirect_to(rule_url(mock_rule))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved rule as @rule" do
        Rule.stub(:new).with({'these' => 'params'}) { mock_rule(:save => false) }
        post :create, :rule => {'these' => 'params'}
        assigns(:rule).should be(mock_rule)
      end

      it "re-renders the 'new' template" do
        Rule.stub(:new) { mock_rule(:save => false) }
        post :create, :rule => {}
        response.should render_template("new")
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested rule" do
        Rule.should_receive(:get).with("37") { mock_rule }
        mock_rule.should_receive(:update).with({'these' => 'params'})
        put :update, :id => "37", :rule => {'these' => 'params'}
      end

      it "assigns the requested rule as @rule" do
        Rule.stub(:get) { mock_rule(:update => true) }
        put :update, :id => "1"
        assigns(:rule).should be(mock_rule)
      end

      it "redirects to the rule" do
        Rule.stub(:get) { mock_rule(:update => true) }
        put :update, :id => "1"
        response.should redirect_to(rule_url(mock_rule))
      end
    end

    describe "with invalid params" do
      it "assigns the rule as @rule" do
        Rule.stub(:get) { mock_rule(:update => false) }
        put :update, :id => "1"
        assigns(:rule).should be(mock_rule)
      end

      it "re-renders the 'edit' template" do
        Rule.stub(:get) { mock_rule(:update => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested rule" do
      Rule.should_receive(:get).with("37") { mock_rule }
      mock_rule.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the rules list" do
      Rule.stub(:get) { mock_rule }
      delete :destroy, :id => "1"
      response.should redirect_to(rules_url)
    end
  end

end
