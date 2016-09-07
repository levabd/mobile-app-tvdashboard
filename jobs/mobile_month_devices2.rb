require 'google/api_client'
require 'date'

# Update these to match your own apps credentials
service_account_email = 'wipon-dashing@dashing-widget-1227.iam.gserviceaccount.com' # Email of service account
key_file = '/home/bitnami/wipon_analytics/Dashing-Widget-a6da79f01f9f.p12' # File containing your private key
key_secret = 'notasecret' # Password to unlock private key
profileID = '101737256' # Analytics profile ID.

# Get the Google API client
client = Google::APIClient.new(:application_name => 'wipon-dashing',
                               :application_version => '0.01')

# Load your credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
client.authorization = Signet::OAuth2::Client.new(
    :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
    :audience => 'https://accounts.google.com/o/oauth2/token',
    :scope => 'https://www.googleapis.com/auth/analytics.readonly',
    :issuer => service_account_email,
    :signing_key => key)

# Start the scheduler
SCHEDULER.every '6h', :first_in => 0 do |job|

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the analytics API
  analytics = client.discovered_api('analytics','v3')

  # Start and end dates
  startDate = DateTime.now.strftime("%Y-%m-01") # First day of month
  endDate = DateTime.now.strftime("%Y-%m-%d")  # now

  # Execute the query
  # Note the trailing to_i - See: https://github.com/Shopify/dashing/issues/33

   regions = client.execute(:api_method => analytics.data.ga.get, :parameters => {
       'ids' => "ga:" + profileID,
       'start-date' => "30daysAgo",
       'end-date' => "yesterday",
       'dimensions' => "ga:mobileDeviceMarketingName",
       'metrics' => "ga:users",
       'sort' => "-ga:users"
  }).data.rows

  items = Array.new 

  for i in 1..5
     items[i-1] = {
       label: regions[i][0],
       value: regions[i][1],
     }
  end

  # Update the dashboard
  send_event('mobile_month_devices2', { items: items })
end