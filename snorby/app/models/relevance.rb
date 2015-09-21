class Relevance

  include DataMapper::Resource

  storage_names[:default] = "sig_class_classification_ids"

  property :id, Serial

  property :sig_class_id, Integer
  property :classification_id, Integer

  attr_accessor :sig_class_name
  attr_accessor :classification_name

end
