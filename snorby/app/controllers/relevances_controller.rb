class RelevancesController < ApplicationController
  # GET /relevances
  # GET /relevances.json

  attr_accessor:categorys
  attr_accessor:classifications

  def index
    @relevances ||= Relevance.all.page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:id.asc])
    @categorys = Category.all
    @classifications = Classification.all

    @relevances.each do |relevance|
      @categorys.each do |category|
        if relevance.sig_class_id == category.sig_class_id
          relevance.sig_class_name = category.sig_class_name
        end
      end

      @classifications.each do |classification|
        if relevance.classification_id == classification.id
          relevance.classification_name = classification.name
        end
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @relevances }
    end
  end

  # GET /relevances/1
  # GET /relevances/1.json
  def show
    @relevance = Relevance.get(params[:id])
    @category = Category.find_by_sig_class_id(@relevance.sig_class_id)
    @classification = Classification.find_by_id(@relevance.classification_id)
    @relevance.sig_class_name = @category.sig_class_name
    @relevance.classification_name = @classification.name
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @relevance }
    end
  end

  # GET /relevances/new
  # GET /relevances/new.json
  def new
    @relevance = Relevance.new
    @classifications = Classification.all
    sql = "select * from sig_class s1 where s1.sig_class_id not in " + 
          "(select s2.sig_class_id from sig_class_classification_ids s2)"

    @categorys = Category.find_by_sql(sql)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @relevance }
    end
  end

  # GET /relevances/1/edit
  def edit
    @relevance = Relevance.get(params[:id])
    @category = Category.find_by_sig_class_id(@relevance.sig_class_id)
    @relevance.sig_class_name = @category.sig_class_name
    @classifications = Classification.all
  end

  # POST /relevances
  # POST /relevances.json
  def create
    @relevance = Relevance.new(params[:relevance])
    if @relevance.sig_class_id != nil && @relevance.classification_id != nil
       flag = @relevance.save
    else 
       flag = false
    end
    respond_to do |format|
      if flag
        format.html { redirect_to @relevance, notice: 'Relevance was successfully created.' }
        format.json { render json: @relevance, status: :created, location: @relevance }
      else
        format.html { redirect_to new_relevance_path, notice: 'Relevance was failed to create.' }
        format.json { render json: @relevance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /relevances/1
  # PUT /relevances/1.json
  def update
    @relevance = Relevance.get(params[:id])
    respond_to do |format|
      if @relevance.update(params[:relevance])
        format.html { redirect_to @relevance, notice: 'Relevance was successfully updated.' }
        #format.html { redirect_to relevances_url, notice: 'Relevance was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @relevance.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @relevance = Relevance.get(params[:id])
    @relevance.classification_id = 9
    @relevance.save

    respond_to do |format|
      format.html { redirect_to relevances_url }
      format.json { head :ok }
    end
  end
  
  # DELETE /relevances/1
  # DELETE /relevances/1.json
=begin
  def destroy
    @relevance = Relevance.get(params[:id])
    @relevance.destroy

    respond_to do |format|
      format.html { redirect_to relevances_url }
      format.json { head :ok }
    end
  end
=end
end
