require 'stripe'
require 'csv'
require 'ruby-limiter'

class CustomerDataPipeline
  extend Limiter::Mixin

  attr_reader :api_key, :csvPath

  # Stripe Search API has a limit of 20 req/sec
  limit_method :getCustomers, rate: 20, interval: 1

  def initialize(api_key, csvPath)
    @api_key = api_key
    @csvPath = csvPath
  end

  def getCustomers(from = {})
    Stripe.api_key = @api_key
    Stripe::Customer.list({ limit: 50, starting_after: from })
  end

  def writeCustomerToCSV(customer = {})
    CSV.open(@csvPath, 'ab') do |csv|
      csv << [customer.id, customer.name]
    end
  end

  def getLastRow
    return [] if File.zero?(@csvPath)

    File.open(@csvPath, skip_blanks: true) do |file|
      file.each_line do |line|
        row = CSV.parse_line(line)
        return row if file.eof?
      end
    end
  end

  def processCustomers
    lastProcessedCustomer = getLastRow
    fromID = {}
    fromID = lastProcessedCustomer[0] if lastProcessedCustomer.length != 0

    while true
      customers = getCustomers(fromID)
      customers.each do |customer|
        writeCustomerToCSV(customer)
      end
      break unless customers.has_more

      fromID = customers.data[-1].id
    end
  end
end
