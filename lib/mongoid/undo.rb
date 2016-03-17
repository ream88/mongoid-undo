require 'active_support'
require 'mongoid'
require 'mongoid/paranoia'
require 'mongoid/versioning'

module Mongoid
  module Undo
    extend ActiveSupport::Concern

    include Mongoid::Paranoia
    include Mongoid::Versioning
    include Mongoid::Interceptable

    # @todo Remove Mongoid 4 support.
    included do
      # _id must be marked as not-versioned
      fields['_id'].options[:versioned] = false
      field :action, type: Symbol, versioned: false
      index deleted_at: 1

      [:create, :update, :destroy].each do |action|
        name = :"set_action_after_#{action}"

        define_method name do
          query = collection.find(atomic_selector)
          set = { '$set' => { action: action } }

          query.respond_to?(:update_one) ? query.update_one(set) : query.update(set)
          version = instance_variable_get(:@version)
          reload
          instance_variable_set :@version, version unless version.nil?
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

    # @todo Remove Mongoid 4 support.
    def retrieve
      attributes = versions.last.versioned_attributes.except('version', 'updated_at')
      respond_to?(:update_one) ? update_one(attributes) : update(attributes)
    end
  end
end
