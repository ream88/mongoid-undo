class Document
  include Mongoid::Document
  include Mongoid::Undo

  field :name, type: String
end

class Localized
  include Mongoid::Document
  include Mongoid::Undo

  field :language, localize: true
end
