# Payload RubyGem

A RubyGem for integrating [Payload](https://payload.co).

## Installation

To install using [Bundler](https://bundler.io):

```ruby
gem 'payload-api', '~> 0.2.3'
```

To install using gem:

```bash
gem install payload
```

## Get Started

Once you've installed the Payload Python library to your environment,
import the `payload` module to get started. **Note:** We recommend
using the shorthand name of `pl` when importing.

```python
import payload as pl
```

### API Authentication

To authenticate with the Payload API, you'll need a live or test API key. API
keys are accessible from within the Payload dashboard.

```python
import payload as pl
pl.api_key = 'secret_key_3bW9JMZtPVDOfFNzwRdfE'
```

### Creating an Object

Interfacing with the Payload API is done primarily through Payload Objects. Below is an example of
creating a customer using the `Payload::Customer` object.


```ruby
# Create a Customer
customer = Payload::Customer.create(
	email: 'matt.perez@example.com',
	name: 'Matt Perez'
)
```


```ruby
# Create a Payment
payment = Payload::Payment.create(
    amount: 100.0,
    payment_method: Payload::Card(
        card_number: '4242 4242 4242 4242'
    )
)
```

### Accessing Object Attributes

Object attributes are accessible through both dot and bracket notation.

```ruby
customer.name
customer['name']
```

### Updating an Object

Updating an object is a simple call to the `update` object method.

```ruby
# Updating a customer's email
customer.update( email: 'matt.perez@newwork.com' )
```

### Selecting Objects

Objects can be selected using any of their attributes.

```ruby
# Select a customer by email
customers = Payload::Customer.filter_by(
    email: 'matt.perez@example.com'
)
```

## Documentation

To get further information on Payload's RubyGem and API capabilities,
visit the unabridged [Payload Documentation](https://docs.payload.co/?ruby).
