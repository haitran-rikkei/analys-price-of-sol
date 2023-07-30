require "csv"

class GetCurrentInfomation
  def initialize
    @s3 = Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION', 'us-west-2'))
  end

  def call
    data = get_current_info&.first
    return if data.blank?

    convert_to_csv(data.slice(*available_keys))
    upload_file
  end

  private

  def get_current_info
    uri = URI(current_info_api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(current_info_api_url, {'Content-Type' => 'application/json'})
    response = http.request(request)
    JSON.parse(response.body) if response.code == '200'
  end

  def current_info_api_url
    'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=solana&order=market_cap_desc&per_page=100&page=1&sparkline=false&locale=en'
  end

  def convert_to_csv(data)
    CSV.open(temp_file.path, 'w' ) do |writer|
      writer << available_keys
      writer << data.values
    end
  end

  def upload_file
    object = @s3.bucket(ENV.fetch('S3_QUICKSIGHT_BUCKET', 'masterstack-s3rawa17ab27b-9tfb3fv0t5g6')).object('current_info/current_info.csv')
    if object.upload_file(temp_file.path)
      puts "Uploaded"
    else
      puts "Not uploaded"
    end
  end

  def available_keys
    %w[current_price total_volume high_24h low_24h price_change_24h price_change_percentage_24h last_updated]
  end

  def temp_file
    @temp_file ||= Tempfile.new("tmp.csv")
  end
end
