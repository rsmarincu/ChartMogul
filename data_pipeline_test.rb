require 'test/unit'
require 'webmock/test_unit'

require_relative 'data_pipeline'

class Customer
  attr_reader :id, :name

  def initialize(id, name)
    @id = id
    @name = name
  end
end

class AppTest < Test::Unit::TestCase
  class << self
    def shutdown
      File.truncate('customerData_test.csv', 0)
    end
  end

  def setup
    @testCSVPath = 'customerData_test.csv'
    @test_writeCustomerToCSV = 'writeCustomerToCSV_test.csv'
  end

  def test_getLastRow_successfully
    customerDataPipeline = CustomerDataPipeline.new('api_key', 'getLastRow_test.csv')
    row = customerDataPipeline.getLastRow

    assert_equal row[0], 'id_2'
  end

  def test_writeCustomerToCSV_succesfully
    customerDataPipeline = CustomerDataPipeline.new('api_key', @test_writeCustomerToCSV)
    customer = Customer.new('test_id', 'John Doe')
    customerDataPipeline.writeCustomerToCSV(customer)
    line = File.open(customerDataPipeline.csvPath, &:readline)
    row = CSV.parse_line(line)

    assert_equal row[0], 'test_id'
    assert_equal row[1], 'John Doe'
  end

  def test_processCustomers_successfully
    customerDataPipeline = CustomerDataPipeline.new('api_key', @testCSVPath)
    mockFirstRequest
    mockSecondRequest

    customerDataPipeline.processCustomers

    linesNumber = File.foreach(@testCSVPath).count

    assert_equal 2, linesNumber
  end
end

def mockFirstRequest
  stub_request(:get, 'https://api.stripe.com/v1/customers?limit=50')
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'Bearer api_key',
        'Content-Type' => 'application/x-www-form-urlencoded',
        'User-Agent' => 'Stripe/v1 RubyBindings/6.5.0',
        'X-Stripe-Client-User-Agent' => '{"bindings_version":"6.5.0","lang":"ruby","lang_version":"2.7.0 p0 (2019-12-25)","platform":"x86_64-linux-gnu","engine":"ruby","publisher":"stripe","uname":"Linux version 4.19.84-microsoft-standard (oe-user@oe-host) (gcc version 8.2.0 (GCC)) #1 SMP Wed Nov 13 11:44:37 UTC 2019","hostname":"DESKTOP-FES6VC2"}'
      }
    )
    .to_return(status: 200, body: toReturn = '
      {
        "object": "list",
        "url": "/v1/customers",
        "has_more": true,
        "data": [
          {
            "id": "cus_BHUJ9EvTcUNOgE",
            "object": "customer",
            "name": "John Doe",
            "address": null,
            "balance": 0,
            "created": 1503719539,
            "currency": "usd",
            "default_currency": "usd",
            "default_source": null,
            "delinquent": false,
            "description": null,
            "discount": null,
            "email": null,
            "invoice_prefix": "9403888",
            "invoice_settings": {
              "custom_fields": null,
              "default_payment_method": null,
              "footer": null,
              "rendering_options": null
            },
            "livemode": false,
            "metadata": {},
            "next_invoice_sequence": 1,
            "phone": null,
            "preferred_locales": [],
            "shipping": null,
            "tax_exempt": "none",
            "test_clock": null
          }
        ]
      }', headers: {})
end

def mockSecondRequest
  stub_request(:get, 'https://api.stripe.com/v1/customers?limit=50&starting_after=cus_BHUJ9EvTcUNOgE')
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'Bearer api_key',
        'Content-Type' => 'application/x-www-form-urlencoded',
        'User-Agent' => 'Stripe/v1 RubyBindings/6.5.0',
        'X-Stripe-Client-User-Agent' => '{"bindings_version":"6.5.0","lang":"ruby","lang_version":"2.7.0 p0 (2019-12-25)","platform":"x86_64-linux-gnu","engine":"ruby","publisher":"stripe","uname":"Linux version 4.19.84-microsoft-standard (oe-user@oe-host) (gcc version 8.2.0 (GCC)) #1 SMP Wed Nov 13 11:44:37 UTC 2019","hostname":"DESKTOP-FES6VC2"}'
      }
    )
    .to_return(status: 200, body: toReturn = '
      {
        "object": "list",
        "url": "/v1/customers",
        "has_more": false,
        "data": [
          {
            "id": "cus_BHUJ9EvTcUNOgE1",
            "object": "customer",
            "address": null,
            "balance": 0,
            "created": 1503719539,
            "currency": "usd",
            "default_currency": "usd",
            "default_source": null,
            "delinquent": false,
            "description": null,
            "discount": null,
            "email": null,
            "invoice_prefix": "9403888",
            "invoice_settings": {
              "custom_fields": null,
              "default_payment_method": null,
              "footer": null,
              "rendering_options": null
            },
            "livemode": false,
            "metadata": {},
            "name": "Johnny Doe",
            "next_invoice_sequence": 1,
            "phone": null,
            "preferred_locales": [],
            "shipping": null,
            "tax_exempt": "none",
            "test_clock": null
          }
        ]
      }', headers: {})
end
