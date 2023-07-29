require "csv"

class SendCrawlerDataToS3
  def initialize
    @s3 = Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION', 'us-west-2'))
  end

  def call
    data = get_prices_chart
    convert_to_csv(data.slice(*available_keys))
    upload_file
  end

  private

  def get_prices_chart
    uri = URI(price_chart_api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(price_chart_api_url, {'Content-Type' => 'application/json'})
    response = http.request(request)
    JSON.parse(response.body)
  end

  def price_chart_api_url
    'https://api.coingecko.com/api/v3/coins/solana/market_chart?vs_currency=usd&days=1'
  end

  def convert_to_csv(data)
    CSV.open(temp_file.path, 'w' ) do |writer|
      writer << ['last_updated_at'] + available_keys
      convert_to_rows(data).each do |val|
        writer << val
      end
    end
  end

  def convert_to_rows(hash)
    prices_hash = hash['prices'].to_h
    market_caps_hash = hash['market_caps'].to_h
    total_volumes_hash = hash['total_volumes'].to_h

    prices_hash.keys.map do |key|
      [key, prices_hash[key], market_caps_hash[key], total_volumes_hash[key]]
    end
  end

  def upload_file
    object = @s3.bucket(ENV.fetch('S3_QUICKSIGHT_BUCKET', 'masterstack-s3rawa17ab27b-9tfb3fv0t5g6')).object('chart/chart.csv')
    if object.upload_file(temp_file.path)
      puts "Uploaded"
    else
      puts "Not uploaded"
    end
  end

  def available_keys
    %w[prices market_caps total_volumes]
  end

  def temp_file
    @temp_file ||= Tempfile.new("tmp.csv")
  end
end
