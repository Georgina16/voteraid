class MessagesController < ApplicationController 
 skip_before_filter :verify_authenticity_token
 #skip_before_filter :authenticate_user!, :only => "reply"
  require 'net/http'
  require 'json'
  include MessagesHelper

  def reply
    message_body = params["Body"]
    from_number = params["From"]
    #check phone sessions to see if user is involved in a current request
    request_id, responder_id = getFromCache(from_number) 
    if request_id.nil?
      @req = Request.create!({phone: from_number, status: 1, responder_id: nil})
      setCache(from_number, @req.id, nil) #Create a phone session for future messages in thread
    else
      @req = Request.find(request_id)
    end
    @message = @req.messages.create({body: message_body})
    boot_twilio
    @nearby = nil
    # when reply, test to return the nearest polling address
    if responder_id and /Y(es)?/i.match(message_body)
      @body = handle_responder(@req, responder_id)
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
        setCache(phone, @req.id, person.id)
      end
    end
  end

  private

  def boot_twilio
    @client = Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_TOKEN"])
  end

  def getFromCache(phone)
    cached = $redis.get phone
    if cached.nil?
      return nil, nil
    else
      cachedObj = JSON.parse(cached)
      return cachedObj["request_id"], cachedObj["responder_id"]
    end
  end

  def setCache(phone, request_id, responder_id)
    $redis.set phone, {"request_id": request_id, "responder_id": responder_id}.to_json
    $redis.expire phone, 24*60*60 #each session expires in 24 hours
  end

end
