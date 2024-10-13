require 'nostr'
require 'pry'
require 'dotenv/load'
require 'httparty'

# event emit code

nsec_server = ENV["NSEC_SERVER"]
npub_server = ENV["NPUB_SERVER"]

keypair = Nostr::KeyPair.new(
  private_key: Nostr::PrivateKey.new(nsec_server),
  public_key: Nostr::PublicKey.new(npub_server),
)

user = Nostr::User.new(keypair: keypair)

relay = Nostr::Relay.new(url: 'wss://relay.damus.io', name: 'Damus')
client = Nostr::Client.new

client.on :connect do |relay|
  filter = Nostr::Filter.new(
    kinds: [5001, 5002],
    since: Time.now.to_i - 3600, # 1 hour ago
    until: Time.now.to_i,
    limit: 20,
  )

  # Subscribe to events matching conditions of a filter
  subscription = client.subscribe(filter: filter)
end


# post payment required event
tags = [
  [ "bid", "1" ],
  [ "t", "bitcoin" ],
  ["status", "payment-required"],
  ["amount", "1", "ecash"],
]

job_feedback_event = Nostr::Event.new(
  pubkey: npub_server,
  kind: 7001,
  tags: tags,
  content: ''
)

job_feedback_event.sign(keypair.private_key)
client.publish(job_feedback_event)

# COMPLETE SEARCH JOB
search_response = HTTParty.get('https://api.nostr.wine/search?query=ecash&kind=1')
parsed_search_results = search_response.fetch('data').map { |data| data['content'] }
# post job result event

job_result_tags = [
  ["request", "<job-request>"],
  ["e", "<job-request-id>", "<relay-hint>"],
  ["i", "<input-data>"],
  ["p", "<customer's-pubkey>"],
  ["amount", "requested-payment-amount", "<optional-bolt11>"]
]

job_result_event = Nostr::Event.new(
  pubkey: npub_server,
  kind: 6001,
  tags: tags,
  content: "RESULT PAYLOAD: #{parsed_search_results}"
)

job_result_event.sign(keypair.private_key)

binding.pry

client.connect(relay)

client.publish(job_feedback_event)
client.publish(job_result_event)

### general behaviour

# * client emits a nip_90_event with the request to search through nostr
# * if dvm sees a message of kind 5001 with a request
# * return the ok and a price (1 sat) 
# * client mints ecash (http library) and pays only set to the npub of the server
# * server does the search (https://api.nostr.wine/search?query=ecash&kind=1) and returns results to client
