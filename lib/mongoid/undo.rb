require 'active_support/concern'
require 'mongoid'

module Mongoid::Fields
  class Localized
    def mongoize(object)
      if object.is_a? ::Hash
        object
      else
        { ::I18n.locale.to_s => type.mongoize(object) }
      end
    end
  end
end


module Mongoid
  module Undo
    extend ActiveSupport::Concern

    include Mongoid::Paranoia
    include Mongoid::Versioning

    included do
      field :_action, type: Symbol, versioned: false
      index deleted_at: 1

      [:create, :update, :destroy].each do |action|
        set_callback action, :after do
          collection.find(atomic_selector).update('$set' => { _action: action })
          reload
        end
      end
    end

    def undo
      case _action
      when :create, :destroy
        deleted_at.present? ? restore : delete
      when :update
        retrieve
      end
    end
    alias_method :redo, :undo

  private
    def retrieve
      update_attributes(versions.last.versioned_attributes.except('version'))
    end
  end
end
