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
    if session["request_id"].nil?
      @req = Request.create!({phone: from_number, status: 1, responder_id: nil})
      @message = @req.messages.create({body: message_body})
    else
      @req = Request.find(session["request_id"])
      if session['responder_id'] and /Y(es)?/i.match(message_body)
        @message = handle_responder(@req, session['responder_id'])
      else
        @message = @req.messages.create({body: message_body})
      end
    end
    session["request_id"] = @req.id
    boot_twilio
    @nearby = nil
    # when reply, test to return the nearest polling address
    if @req.status == 5
      @body, @nearby = handle_help_request(@req, @message)
    else
      @body = handler(@req, @message)
    end
    sms = @client.messages.create(
      from: ENV["TWILIO_NUMBER"],
      to: from_number,
      body: "Request ID: #{@req.id}. Your number is #{from_number}. \
         #{@body}"
    )
    if @nearby
      from = ENV["TWILIO_NUMBER"]
      issue = index_to_issue(@req.issue)
      @nearby.each do |person|
        session["request_id"] = @req.id
        session["responder_id"] = person.id
        @client.account.messages.create(
          :from => from,
          :to => person.phone,
          :body => "Hi, someone near #{@req.address} needs your help. He/She is facing \
        the issue of " + issue +  " Specfically, the description is: #{@req.desc}"
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
