require 'nostr'
require 'pry'
require 'dotenv/load'
require 'httparty'

class Dvm
  def initialize(
      nsec_dvm: ENV['NSEC_DVM'],
      npub_dvm: ENV['NPUB_DVM']
    )

    @nsec_dvm = nsec_dvm
    @npub_dvm = npub_dvm

    @keypair = Nostr::KeyPair.new(
      private_key: Nostr::PrivateKey.new(nsec_dvm),
      public_key: Nostr::PublicKey.new(npub_dvm),
    )

    client.connect(relay)
  end

  def send_payment_required_event
    tags = [
      [ "bid", "1" ],
      [ "t", "bitcoin" ],
      ["status", "payment-required"],
      ["amount", "1", "ecash"],
    ]

    job_feedback_event = Nostr::Event.new(
      pubkey: npub_dvm,
      kind: 7001,
      tags: tags,
      content: ''
    )

    job_feedback_event.sign(keypair.private_key)
    client.publish(job_feedback_event)
  end

  def perform_job
    search_response = HTTParty.get('https://api.nostr.wine/search?query=ecash&kind=1')
    @parsed_search_results = search_response.fetch('data').map { |data| data['content'] }
  end

  def send_job_result_event
    job_result_tags = [
      ["request", "<job-request>"],
      ["e", "<job-request-id>", "<relay-hint>"],
      ["i", "<input-data>"],
      ["p", "<customer's-pubkey>"],
    ]

    job_result_event = Nostr::Event.new(
      pubkey: npub_dvm,
      kind: 6001,
      tags: job_result_tags,
      content: "RESULT PAYLOAD: #{@parsed_search_results}"
    )

    job_result_event.sign(keypair.private_key)

    client.publish(job_result_event)
  end

  private

  attr_reader :keypair, :nsec_dvm, :npub_dvm

  def client
    @client ||= Nostr::Client.new
  end

  def relay
    @relay ||= Nostr::Relay.new(url: 'wss://relay.damus.io',
                                name: 'Damus')
  end
end

dvm = Dvm.new
binding.pry
dvm.send_payment_required_event
dmv.perform_job
dvm.send_job_result_event
