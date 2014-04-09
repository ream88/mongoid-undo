require 'active_support'
require 'mongoid'
require 'mongoid/paranoia'
require 'mongoid/versioning'

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
        name = :"set_action_after_#{action}"

        define_method name do
          collection.find(atomic_selector).update('$set' => { action: action })
          version = self.instance_variable_get(:@version)
          reload
          self.instance_variable_set :@version, version unless version.nil?
        end
        set_callback action, :after, name
      end

      after_find do
        @version = read_attribute(:version)
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

    def undoable?
      case action
      when :create, :destroy
        true
      when :update
        read_attribute(:version).to_i > @version
      end
    end
    alias_method :redoable?, :undoable?

  private
    def retrieve
      update_attributes(versions.last.versioned_attributes.except('version', 'updated_at'))
    end
  end
end
