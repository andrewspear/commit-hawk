require 'sinatra'
require 'json'
require 'pry-remote'

post '/payload' do
  request.body.rewind
  payload_body = request.body.read
  
  verify_signature(payload_body)
  
  push = JSON.parse(params[:payload])
  watching = params[:watching]

  if (commits = watched_changes(watching, push['commits'])).length > 0
    ids = commits.map{ |c| c['id'] }.join(', ')
    "Wow things changed in: #{ids}"
  else
    "Meh I don't care"
  end
end

def watched_changes(watching, commits)
  commits.select do |commit|
    commit['modified'].any?{ |added| added.start_with?(watching) } 
  end
end

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end
