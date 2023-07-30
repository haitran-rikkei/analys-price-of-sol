class Quicksight
  attr_reader :dashboard, :client

  def initialize(dashboard_id: nil)
    @client = Aws::QuickSight::Client.new
    @dashboard = dashboard_id.presence || default_dashboard_id
  end

  def generate_url(params = {})
    response = @client.generate_embed_url_for_anonymous_user(generate_url_params.merge(params))
    response.embed_url if response.status.to_s == '200'
  end

  def get_dashboard_embed_url
    res = @client.get_dashboard_embed_url({
      aws_account_id: ENV['QUICKSIGHT_AWS_ACCOUNT_ID'], # required
      dashboard_id: dashboard, # required
      identity_type: 'ANONYMOUS', # required, accepts IAM, QUICKSIGHT, ANONYMOUS
      session_lifetime_in_minutes: 60,
      undo_redo_disabled: false,
      reset_disabled: false,
      state_persistence_enabled: false,
      namespace: 'default',
    })
    res.embed_url if res.status.to_s == '200' 
  end

  private

  def generate_url_params
    {
      aws_account_id: ENV['QUICKSIGHT_AWS_ACCOUNT_ID'],
      namespace: 'default',
      session_lifetime_in_minutes: 60,
      authorized_resource_arns: ["arn:aws:quicksight:#{ENV['AWS_REGION']}:#{ENV['QUICKSIGHT_AWS_ACCOUNT_ID']}:dashboard/#{dashboard}"],
      experience_configuration: {
        dashboard: {
          initial_dashboard_id: dashboard,  #"ShortRestrictiveResourceId", # required
        },
      }
    };
  end

  def default_dashboard_id
    ENV.fetch('DEFAULT_DASHBOARD_ID', '9169e936-28ce-451d-aa2a-80efc74e5d44')
  end
end
