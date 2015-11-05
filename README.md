# mongoid-undo

Super simple undo for your Mongoid app, based on both great modules
[Mongoid::Paranoia](http://mongoid.org/en/mongoid/docs/extras.html#paranoia) and
[Mongoid::Versioning](http://mongoid.org/en/mongoid/docs/extras.html#versioning).

## How does it work?

* `Mongoid::Paranoia` is used to mark documents as deleted, instead of deleting them really, otherwise restoring would be impossible ;).
* `Mongoid::Versioning` is used to keep the older versions of your document, so we can restore them.
* `Mongoid::Undo` adds an `action` field to your documents, so we can easily determine whether it was created, updated, or destroyed.

But instead of explaining all the details, you should get the idea by looking at the [Usage](https://github.com/haihappen/mongoid-undo#usage) section.


## Installation

In your Gemfile:

```ruby
gem 'mongoid-undo'
```


## Usage

```ruby
class Document
  include Mongoid::Document
  include Mongoid::Undo
end
```


### Creating (and undoing)

```ruby
document = Document.create
document.persisted? #=> true

document.undo
document.persisted? #=> false

document.redo # A nice alias for undo ;)
document.persisted? #=> true
```


### Updating (and undoing)

```ruby
document = Document.create(name: 'foo')

document.undoable? # => false
document.save
document.undoable? # => false

document.update_attributes(name: 'bar')
document.undoable? # => true
document.name #=> 'bar'

document.undo
document.name #=> 'foo'

document.redo
document.name #=> 'bar'
```


### Destroying (and undoing)

```ruby
document = Document.first

document.destroy
document.persisted? #=> false

document.undo
document.persisted? #=> true

document.redo
document.persisted? #=> false
```


### Callbacks

Mongoid::Undo defines two callbacks which are called before and after `undo`, respectively `redo`. Both are based on `ActiveModel::Callbacks` which means they behave like the already known Rails callbacks.

```ruby
class Document
  include Mongoid::Document
  include Mongoid::Undo

  before_undo do
    # Do something fancy.
  end

  before_redo { false } # Don't allow redoing.
end
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Copyright

(The MIT license)

Copyright (c) 2012-2015 Mario Uher

See LICENSE.md.
