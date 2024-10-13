require 'nostr'
require 'pry'
require 'dotenv/load'

class Customer
  def initialize(
      nsec: ENV['NSEC'],
      npub: ENV['NPUB']
    )

    @nsec = nsec
    @npub = npub

    @keypair = Nostr::KeyPair.new(
      private_key: Nostr::PrivateKey.new(nsec),
      public_key: Nostr::PublicKey.new(npub),
    )

    client.connect(relay)
  end

  def send_job_request_event
    tags = [
      ["i", "ecash", "search query"],
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

    client.publish(job_request_event)
  end

  def send_job_payment_event
    ecash_token = ENV["ECASH_TOKEN"] # set only to npub of dvm

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

    client.publish(job_payment_event)
  end

  private

  attr_reader :keypair, :npub, :nsec

  def client
    @client ||= Nostr::Client.new
  end

  def relay
    @relay ||= Nostr::Relay.new(url: 'wss://relay.damus.io',
                                name: 'Damus')
  end

  def user
    @user || Nostr::User.new(keypair: keypair)
  end
end

customer = Customer.new
binding.pry
customer.send_job_request_event
customer.send_job_payment_event
