class MessagesController < ApplicationController 
 skip_before_filter :verify_authenticity_token
 #skip_before_filter :authenticate_user!, :only => "reply"
  require 'net/http'
  require 'json'
  include MessagesHelper

  use Rack::Session::Cookie, :key => 'rack.session',
                             :path => '/',
                             :secret => ENV["SECRET_KEY_BASE"]

  def reply
    message_body = params["Body"]
    from_number = params["From"]
    @responder = Responder.find_by phone: from_number 
    if session["request_id"].nil? && @responder.nil?
      @req = Request.create!({phone: from_number, status: 1, responder_id: nil})
      @message = @req.messages.create({body: message_body})
    else
      if @responder
        @req = Request.last #TEMPORARY PENDING KEY-VALUE CACHE OF RESPONDERS TO REQUESTS
      else
        @req = Request.find(session["request_id"])
      end
      @message = @req.messages.create({body: message_body})
    end
    session["request_id"] = @req.id
    boot_twilio
    @nearby = nil
    # when reply, test to return the nearest polling address
    if @responder and /Y(es)?/i.match(message_body)
      @body = handle_responder(@req, @responder.id)
    else
      @body, @nearby = handler(@req, @message)
    end
    sms = @client.messages.create(
      from: ENV["TWILIO_NUMBER"],
      to: from_number,
      body: @body
    )
    if @nearby
      from = ENV["TWILIO_NUMBER"]
      issue = t(@req.issue, scope: :issues)
      @nearby.each do |person|
        @client.account.messages.create(
          :from => from,
          :to => person.phone,
          :body => t(:nearby, address: @req.address, issue: issue, desc: @req.desc)
        )
        puts "Sent request for help to #{person.fname}"
      end
    end
  end

  private

  def boot_twilio
    @client = Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_TOKEN"])
  end


end
