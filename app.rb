require "sinatra"
require 'sinatra/reloader' if development?
require 'alexa_skills_ruby'
require 'httparty'
require 'iso8601'
require 'twilio-ruby'

# ----------------------------------------------------------------------

# Load environment variables using Dotenv. If a .env file exists, it will
# set environment variables from that file (useful for dev environments)
configure :development do
  require 'dotenv'
  Dotenv.load
end

# enable sessions for this project
enable :sessions


# ----------------------------------------------------------------------
#     How you handle your Alexa
# ----------------------------------------------------------------------

class CustomHandler < AlexaSkillsRuby::Handler

  on_intent("GREETING") do
		# add a response to Alexa
    response.set_output_speech_text("How are you today?")
		# create a card response in the alexa app
    response.set_simple_card("out of office App", "Status is in the office.")
		# log the output if needed
    logger.info 'Greeting processed'
		# send a message to slack
    update_status "GREETING"
  end

  on_intent("CHECKSTUDY") do
    # add a response to Alexa
    response.set_output_speech_text("Good! I am your study bot. Welcome to study with me and you can say Help to get to know me more. Or you can start your study today now by saying study now")
    # create a card response in the alexa app
    response.set_simple_card("out of office App", "Status is in the office.")
    # log the output if needed
    logger.info 'CHECKSTUDY processed'
    # send a message to slack
    update_status "CHECKSTUDY"
  end

  on_intent("AMAZON.HelpIntent") do
    response.set_output_speech_text("I am your study buddy when you study at home. You can set study time and I will count down for you. I can also provide music and white noices to help you study. I can also tell jokes to help you feel relax. Trying to say study now to start your study today:)")
    logger.info 'HelpIntent processed'
  end

  on_intent("JOKES") do
    # add a response to Alexa
    response.set_output_speech_text("A bear walks into a bar and says, Give me a whiskey and cola.
Why the big pause? asks the bartender. The bear shrugged. I'm not sure. I was born with them.")
    # create a card response in the alexa app
    response.set_simple_card("out of office App", "Status is in the office.")
    # log the output if needed
    logger.info 'JOKES processed'
    # send a message to slack
    update_status "JOKES"
  end


  on_intent("STUDYTIME") do
		# add a response to Alexa
    response.set_output_speech_ssml("<speak>
    <amazon:emotion name='excited' intensity='medium'>
        Let's start now! You will receive a message as the count down starts.
    </amazon:emotion>
</speak>")
		# create a card response in the alexa app
    response.set_simple_card("out of office App", "Status is in the office.")
		# log the output if needed
    logger.info 'STUDYTIME'
		# send a message to slack
    update_status "STUDYTIME"


  end

  on_intent("STUDYTIMEEND") do
    # add a response to Alexa
    response.set_output_speech_ssml("<speak>
    <amazon:emotion name='excited' intensity='medium'>
        You did a really good job!
    </amazon:emotion>
  </speak>")
    # create a card response in the alexa app
    response.set_simple_card("out of office App", "Status is in the office.")
    # log the output if needed
    logger.info 'STUDYTIMEEND'
    # send a message to slack
    update_status "STUDYTIMEEND"


  end

  on_intent("BACK_IN") do

		# Access the slots
    slots = request.intent.slots
    puts slots.to_s

		# Duration is returned in a particular format
		# Called ISO8601. Translate this into seconds
    duration = ISO8601::Duration.new( request.intent.slots["duration"] ).to_seconds

		# This will downsample the duration from a default seconds
		# To...
    if duration > 60 * 60 * 24
      days = duration/(60 * 60 * 24).round
      response.set_output_speech_text("I've set you away for #{ days } days")
    elsif duration > 60 * 60
      hours = duration/(60 * 60 ).round
      response.set_output_speech_text("I've set you away for #{ hours } hours")
    else
      mins = duration/(60).round
      response.set_output_speech_text("I've set you away for #{ mins } minutes")
    end
    logger.info 'BackIn processed'
    update_status "BACK_IN"
  end

  on_intent("GetZodiacHoroscopeIntent") do
    slots = request.intent.slots
    response.set_output_speech_text("Horoscope Text")
    #response.set_output_speech_ssml("<speak><p>Horoscope Text</p><p>More Horoscope text</p></speak>")
    response.set_reprompt_speech_text("Reprompt Horoscope Text")
    #response.set_reprompt_speech_ssml("<speak>Reprompt Horoscope Text</speak>")
    response.set_simple_card("title", "content")
    logger.info 'GetZodiacHoroscopeIntent processed'
  end


end

# ----------------------------------------------------------------------
#     ROUTES, END POINTS AND ACTIONS
# ----------------------------------------------------------------------


get '/' do
  404
end


# THE APPLICATION ID CAN BE FOUND IN THE


post '/incoming/alexa' do
  content_type :json

  handler = CustomHandler.new(application_id: ENV['ALEXA_APPLICATION_ID'], logger: logger)

  begin
    hdrs = { 'Signature' => request.env['HTTP_SIGNATURE'], 'SignatureCertChainUrl' => request.env['HTTP_SIGNATURECERTCHAINURL'] }
    handler.handle(request.body.read, hdrs)
  rescue AlexaSkillsRuby::Error => e
    logger.error e.to_s
    403
  end

end

# # Build a twilio response object
# twiml = Twilio::TwiML::MessagingResponse.new do |r|
#   r.message do |m|
#
#     # add the text of the response
#     m.body( message )
#
#     # add media if it is defined
#     unless media.nil?
#       m.media( media )
#     end
#   end
# end
#
# # increment the session counter
# session["counter"] += 1
#
# # send a response to twilio
# content_type 'text/xml'
# twiml.to_s

# end



# ----------------------------------------------------------------------
#     ERRORS
# ----------------------------------------------------------------------



error 401 do
  "Not allowed!!!"
end

# ----------------------------------------------------------------------
#   METHODS
#   Add any custom methods below
# ----------------------------------------------------------------------

private

def update_status status

# Default response
  message = "other/unknown"

# looks up a message based on the Status provided
  if status == "STUDYTIME"
    message = ENV['APP_USER'].to_s + ", study time begins."
  # #elsif status == "BACK_IN"
  #   message = ENV['APP_USER'].to_s + " will be back in #{(duration/60).round} minutes"
  # elsif status == "BE_RIGHT_BACK"
  #   message = ENV['APP_USER'].to_s + " will be right back"
  # elsif status == "GONE_HOME"
  #   message = ENV['APP_USER'].to_s + " has left for the day. Check back tomorrow."
  # elsif status == "DO_NOT_DISTURB"
  #   message = ENV['APP_USER'].to_s + " is busy. Please do not disturb."
  end


  client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
  message="The countdown is starting now!"
  client.api.account.messages.create(
    from: ENV["TWILIO_FROM"],
    to: "+14128971376",
    body: message
  )

end

# def post_to_slack status_update, message
#
# # look up the Slack url from the env
#   slack_webhook = ENV['SLACK_WEBHOOK']
#
# # create a formatted message
#   formatted_message = "*Study time begins for #{ENV['APP_USER'].to_s}"
#   #to: #{status_update}*\n
#   formatted_message += "#{message} "
#
# # Post it to Slack
#   HTTParty.post slack_webhook, body: {text: formatted_message.to_s, username: "studywithmeBot", channel: "back" }.to_json, headers: {'content-type' => 'application/json'}
#
# end
