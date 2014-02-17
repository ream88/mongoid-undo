require_relative 'test_helper'

class Document
  include Mongoid::Document
  include Mongoid::Undo

  field :name, type: String
end

class Localized
  include Mongoid::Document
  include Mongoid::Undo

  field :language, localize: true, type: String
end

class Timestamped
  include Mongoid::Document
  include Mongoid::Undo
  include Mongoid::Timestamps

  field :name, type: String
end

class UndoTest < Minitest::Unit::TestCase
  def test_create
    document = Document.create(name: 'foo')
    assert_equal :create, document.action
    assert_equal 1, document.version
    assert document.persisted?

    document.undo
    assert_equal :create, document.action
    assert_equal 1, document.version
    assert_not document.persisted?

    document.redo
    assert_equal :create, document.action
    assert_equal 1, document.version
    assert document.persisted?
  end


  def test_update
    document = Document.create(name: 'foo')

    document.update_attributes name: 'bar'
    assert_equal :update, document.action
    assert_equal 2, document.version
    assert_equal 'bar', document.name

    document.undo
    assert_equal :update, document.action
    assert_equal 3, document.version
    assert_equal 'foo', document.name

    document.redo
    assert_equal :update, document.action
    assert_equal 4, document.version
    assert_equal 'bar', document.name
  end


  def test_destroy
    document = Document.create(name: 'foo')

    document.destroy
    assert_equal :destroy, document.action
    assert_not document.persisted?

    document.undo
    assert_equal :destroy, document.action
    assert document.persisted?

    document.redo
    assert_equal :destroy, document.action
    assert_not document.persisted?
  end


  def test_redo_equals_to_undo
    document = Document.create(name: 'foo')

    assert_equal document.method(:undo), document.method(:redo)
  end


  def test_localized_attributes
    document = Localized.create(language: 'English')

    document.update_attributes language: 'English Updated'
    document.undo
    assert_equal 'English', document.language

    document.redo
    assert_equal 'English Updated', document.language
  end


  def test_updated_at_timestamp
    document = Timestamped.create(name: 'foo')
    updated_at = document.updated_at

    document.update_attributes(name: 'bar')
    assert_not_equal updated_at, document.updated_at

    document.undo
    assert_not_equal updated_at, document.updated_at

    document.redo
    assert_not_equal updated_at, document.updated_at
  end
end
