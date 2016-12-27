module MessagesHelper
  require 'net/https'
  require 'uri'
  require 'twilio-ruby'
  
  def handler(req, message)
    puts "Incoming request status : #{req.status} - #{message.body}"
    if req.process(:nil, message) #feeds the message into status state machine of Request
      case req.status
          when :pending_responder
            return handle_help_request(req, message)
          when :check_need_responder
            return handle_issue(req, message)
          else
            return t(req.status), nil
      end
    else
      return t(:process_error) + t(req.status),nil
    end
  end

  # status 3
  def handle_issue(req, message) #only gives more info for check in specific cases right now
    if (req.issue == :check_in) #issue with checking in
      info = find_poll_addr(req.address)
    end
    info = info || ""
    return info + t(:check_need_responder), nil
  end

  # helper func in status 3
  def find_poll_addr(message_addr)
    uri = URI.parse('https://www.googleapis.com/civicinfo/v2/voterinfo?address=' + \
      message_addr + '&electionId=2000&key=' + ENV["GOOGLE_API_KEY"])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    res_hash = JSON.parse(response.body)
          address_hash = res_hash['pollingLocations'][0]['address']
          locationName = address_hash['locationName']
          line1 = address_hash['line1'] || ""
          line2 = address_hash['line2'] || ""
          line3 = address_hash['line3'] || ""
          return "We found the closest polling location to you:\n" + locationName+line1+line2+line3 + "\n"
  end

  # status 5 
  def handle_help_request(req, message)
    return t(:pending_responder), Responder.near(req.address, 50).limit(5)
  end   
 
  # status 6
  def handle_responder(req,responder_id)
      if confirm_respondent(req, responder_id)
        req.process(responder_id)
        send_confirm_to_requester(req)
        return t(responder_offers_help)
      else
        return t(:responder_already_assigned)
      end
  end

  # helper status 6
  def send_confirm_to_requester(req)
    @client = Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_TOKEN"])
    from = ENV["TWILIO_NUMBER"] 
    responder = req.responder
    @client.account.messages.create(
      :from => from,
      :to => req.phone,
      :body => t(:responder_assigned, responder: responder.fname, phone: responder.phone)
    )
  end

  # helper status 6
  def confirm_respondent(req, responder_id)
   # check that respondent exist and request status is 6
    if req.status != :pending_responder
      return false
    end
    return !Responder.find(responder_id).nil?
  end

  


end
