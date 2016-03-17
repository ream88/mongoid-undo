require_relative 'test_helper'

class Document
  include Mongoid::Document
  include Mongoid::Undo

  field :name, type: String
end

class Localized < Document
  field :language, localize: true, type: String
end

class Timestamped < Document
  include Mongoid::Timestamps
end

class UndoTest < Minitest::Test
  def test_create
    document = Document.create(name: 'foo')
    assert_equal :create, document.action
    assert_equal 1, document.version
    assert document.persisted?
    assert document.undoable?

    document.undo
    assert_equal :create, document.action
    assert_equal 1, document.version
    refute document.persisted?
    assert document.undoable?

    document.redo
    assert_equal :create, document.action
    assert_equal 1, document.version
    assert document.persisted?
    assert document.undoable?
  end

  def test_update
    document = Document.create(name: 'foo')

    document.save
    refute document.undoable?

    document.update_attributes name: 'bar'
    assert_equal :update, document.action
    assert_equal 2, document.version
    assert_equal 'bar', document.name
    assert document.undoable?

    document.undo
    assert_equal :update, document.action
    assert_equal 3, document.version
    assert_equal 'foo', document.name
    assert document.undoable?

    document.redo
    assert_equal :update, document.action
    assert_equal 4, document.version
    assert_equal 'bar', document.name
    assert document.undoable?
  end

  def test_destroy
    document = Document.create(name: 'foo')

    document.destroy
    assert_equal :destroy, document.action
    refute document.persisted?
    assert document.undoable?

    document.undo
    assert_equal :destroy, document.action
    assert document.persisted?
    assert document.undoable?

    document.redo
    assert_equal :destroy, document.action
    refute document.persisted?
    assert document.undoable?
  end

  def test_redo_equals_to_undo
    document = Document.create(name: 'foo')

    assert_equal document.method(:undo), document.method(:redo)
  end

  def test_redoable_equals_to_undoable
    document = Document.create(name: 'foo')

    assert_equal document.method(:undoable?), document.method(:redoable?)
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
    refute_equal updated_at, document.updated_at

    document.undo
    refute_equal updated_at, document.updated_at

    document.redo
    refute_equal updated_at, document.updated_at
  end

  def test_callbacks
    document = Document.create(name: 'foo')
    mock = MiniTest::Mock.new

    document.class.before_undo { mock.before_undo }
    document.class.after_undo { mock.after_undo }

    mock.expect :before_undo, nil
    mock.expect :after_undo, nil

    document.undo
    mock.verify

    document.class.before_redo { mock.before_redo }
    document.class.after_redo { mock.after_redo }

    mock.expect :before_redo, nil
    mock.expect :after_redo, nil

    document.redo
    mock.verify
  end

  def test_around_callback
    document = Document.create(name: 'foo')
    document.update_attributes name: 'bar'

    tap do |test|
      document.class.around_undo do |document, proc|
        test.assert_equal 'bar', document.name
        proc.call
        test.assert_equal 'foo', document.name
      end
    end

    document.undo
  end

  def test_disabling_undo_via_callbacks
    document = Document.create(name: 'foo')
    document.destroy

    # Disable undoing
    document.class.before_undo proc { false }

    assert_no_difference 'Document.count' do
      document.undo
    end
  end

  def teardown
    Document.reset_callbacks :undo
    Document.reset_callbacks :redo
  end
end
