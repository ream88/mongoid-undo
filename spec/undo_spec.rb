require File.expand_path('../spec_helper', __FILE__)

module Mongoid
  module Undo
    describe self do
      include ActiveSupport::Testing::Assertions

      class Document
        include Mongoid::Document
        include Mongoid::Undo
        
        field :name, type: String
      end


      subject { Document.create(name: 'Version 1') }


      describe 'undoing create' do
        before { subject.undo }


        it 'deletes' do
          subject.persisted?.wont_equal true
          subject.deleted_at.wont_be_nil
        end


        describe 'and then redoing' do
          it 'redoes' do
            subject.redo
            
            subject.persisted?.must_equal true
            subject.deleted_at.must_be_nil
          end
        end


        it 'returns proper state' do
          3.times do
            subject.undo
            subject.action.must_equal :create
          end
        end
      end


      describe 'undoing update' do
        before { subject.update_attributes(name: subject.name.next) }


        it 'creates a new version' do
          assert_difference 'subject.version', +1 do
            subject.undo
          end
          
          # Ensure the new version is saved to the db
          subject.persisted?.must_equal true
          subject.name.must_equal 'Version 1'
        end


        it 'returns proper state' do
          3.times do
            subject.undo
            subject.action.must_equal :update
          end
        end
      end


      describe 'undoing destroy' do
        describe 'having one version' do
          before { subject.destroy }


          it 'restores' do
            subject.undo
            
            subject.persisted?.must_equal true
            subject.deleted_at.must_be_nil
          end


          it 'returns proper state' do
            3.times do
              subject.undo
              subject.action.must_equal :destroy
            end
          end
        end


        describe 'having multiple versions' do
          before do
            3.times { subject.update_attributes(name: subject.name.next) }
            subject.destroy
          end


          it 'restores' do
            assert_difference 'subject.version', 0 do
              subject.undo
            end
            
            subject.persisted?.must_equal true
            subject.deleted_at.must_be_nil
          end


          it 'returns proper state' do
            3.times do
              subject.undo
              subject.action.must_equal :destroy
            end
          end
        end
      end


      describe :redo do
        it 'is a convenient alias for undo' do
          subject.method(:redo).must_equal subject.method(:undo)
        end
      end


      describe :state do
        it 'is a symbol' do
          subject.fields['action'].options[:type].must_equal Symbol
        end


        it 'is versionless' do
          subject.fields['action'].options[:versioned].must_equal false
        end
      end


      describe :retrieve do
        class Localized
          include Mongoid::Document
          include Mongoid::Undo
          
          field :language, localize: true
        end


        subject { Localized.new }


        it 'works too with localized fields' do
          subject.update_attributes language: 'English'
          subject.update_attributes language: 'English Updated'
          
          assert_difference 'subject.version', +1 do
            subject.send(:retrieve)
          end
          subject.language.must_equal 'English'
          
          assert_difference 'subject.version', +1 do
            subject.send(:retrieve)
          end
          subject.language.must_equal 'English Updated'
        end


        after { I18n.locale = I18n.default_locale }
      end
    end
  end
end
