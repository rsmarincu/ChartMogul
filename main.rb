require_relative 'data_pipeline'

stripeAPIKey = 'sk_test_RsUIbMyxLQszELZQEXHTeFA9008YRV7Vhr'
csvOutputPath = 'customerData.csv'

customerDataPipeline = CustomerDataPipeline.new(stripeAPIKey, csvOutputPath)
customerDataPipeline.processCustomers
