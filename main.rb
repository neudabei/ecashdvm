require 'nostr'
require 'pry'
require 'dotenv/load'

nsec = ENV["NSEC"]
npub = ENV["NPUB"]

ecash_token = ENV["ECASH_TOKEN"] # only set to npub of dvm

keypair = Nostr::KeyPair.new(
  private_key: Nostr::PrivateKey.new(nsec),
  public_key: Nostr::PublicKey.new(npub),
)

client = Nostr::Client.new
relay = Nostr::Relay.new(url: 'wss://relay.damus.io', name: 'Damus')

user = Nostr::User.new(keypair: keypair)

tags = [
  ["i", "ecash", "query"],
  ["bid", "1"],
  ["t", "bitcoin"]
]

job_request_event = Nostr::Event.new(
  pubkey: npub,
  kind: 5001,
  tags: tags,
  content: 'i haz job 4 u'
)
job_request_event.sign(keypair.private_key)

# client.on :connect do |relay|
#   filter = Nostr::Filter.new(
#     kinds: [7001, 6001],
#     since: Time.now.to_i - 3600, # 1 hour ago
#     until: Time.now.to_i,
#     limit: 20,
#   )

#   # Subscribe to events matching conditions of a filter
#   subscription = client.subscribe(filter: filter)
# end

job_payment_tags = [
  ["takedeeznuts", "ecash_token"],
  ["amount", "1", "ecash"]
]

job_payment_event = Nostr::Event.new(
  pubkey: npub,
  kind: 5002,
  tags: job_payment_tags,
  content: ''
)

job_payment_event.sign(keypair.private_key)

### 
binding.pry

client.connect(relay)

# post request event
client.publish(job_request_event)

# post payment event
client.publish(job_payment_event)
