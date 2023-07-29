class Quicksight
  def initialize
    @client = Aws::QuickSight::Client.new
  end

  def generate_url(params = {})
    response = @client.generate_embed_url_for_anonymous_user(generate_url_params.merge(params))
    response.embed_url if response.status == 200
  end

  def generate_url_params
    {
      aws_account_id: ENV['QUICKSIGHT_AWS_ACCOUNT_ID'],
      namespace: 'default',
      session_lifetime_in_minutes: 60,
      authorized_resource_arns: ["arn:aws:quicksight:#{ENV['AWS_REGION']}:#{ENV['QUICKSIGHT_AWS_ACCOUNT_ID']}:dashboard/#{dashboard_id}"],
      experience_configuration: {
        dashboard: {
          initial_dashboard_id: dashboard_id,  #"ShortRestrictiveResourceId", # required
        },
      }
    };
  end

  def dashboard_id
    '9169e936-28ce-451d-aa2a-80efc74e5d44'
  end
end
