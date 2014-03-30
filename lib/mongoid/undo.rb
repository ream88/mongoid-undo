require 'active_support'
require 'mongoid'

module Mongoid
  module Undo
    extend ActiveSupport::Concern

    include Mongoid::Paranoia
    include Mongoid::Versioning
    include Mongoid::Callbacks

    included do
      field :action, type: Symbol, versioned: false
      index deleted_at: 1

      [:create, :update, :destroy].each do |action|
        set_callback action, :after do
          collection.find(atomic_selector).update('$set' => { action: action })
          reload
        end
      end

      define_model_callbacks :undo, :redo
    end

    def undo
      run_callbacks __callee__ do
        case action
        when :create, :destroy
          deleted_at.present? ? restore : delete
        when :update
          retrieve
        end
      end
    end
    alias_method :redo, :undo

  private
    def retrieve
      update_attributes(versions.last.versioned_attributes.except('version', 'updated_at'))
    end
  end
end
