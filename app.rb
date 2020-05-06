require "sinatra"
require 'sinatra/reloader' if development?

require 'alexa_skills_ruby'
require 'httparty'
require 'iso8601'




# ----------------------------------------------------------------------

# Load environment variables using Dotenv. If a .env file exists, it will
# set environment variables from that file (useful for dev environments)
configure :development do
  require 'dotenv'
  Dotenv.load
end

# enable sessions for this project
enable :sessions


#post '/' do
  #Ralyxa::Skill.handle(request)
#end

# ----------------------------------------------------------------------
#     How you handle your Alexa
# ----------------------------------------------------------------------

class CustomHandler < AlexaSkillsRuby::Handler


  #on_intent("firstsentence") do
  #ask("How are you today?")
#end

on_intent("firstsentence") do
  # add a response to Alexa
  response.set_output_speech_text("How are you doing ")
  # create a card response in the alexa app
  response.set_simple_card("study with me App", "firstsentence.")
  # log the output if needed
  logger.info 'firstsentence processed'
  # send a message to slack
  update_status "firstsentence."
end

  on_intent("Greeting") do
    # add a response to Alexa
    response.set_output_speech_text("I am doing well! I am your study buddy! You can ask 'who are you' to know more about me or directly go to study by saying ’study time begins ")
    # create a card response in the alexa app
    response.set_simple_card("study with me App", "Study time from now on.")
    # log the output if needed
    logger.info 'Greeting processed'
    # send a message to slack
    update_status "Greeting."
  end

  #intent "PlayAudio" do
  #audio_player.play(
    #'https://s3.amazonaws.com/my-ssml-samples/Flourish.mp3',
  #  'flourish-token',
    #speech: 'Playing Audio'
  #)
#end


  on_intent("AMAZON.HelpIntent") do
    # add a response to Alexa
    response.set_output_speech_text("I am your study buddy. I can help you set study time for your everyday study. You can set multiple rounds of study and each round will lasting 30 minutes, including 25-minute studying time and 5-minute rest time. Also I can provide you different help in your study process. You can call me to tell jokes or help you find music you like. ")
    # create a card response in the alexa app
    response.set_simple_card("study with me App", "Study time from now on.")
    # log the output if needed
    logger.info 'Help processed'
    # send a message to slack
    update_status "Morning."
  end

  on_intent("Studytime") do
		# add a response to Alexa
    response.set_output_speech_text("How long time would like to study now?")
		# create a card response in the alexa app
    response.set_simple_card("Study with me app", "setstudytime.")
		# log the output if needed
    logger.info 'studytime'
		# send a message to slack
    update_status "studytime"
  end

  on_intent("music") do
		# add a response to Alexa
    response.set_output_speech_ssml("audio src='https://mc2method.org/white-noise/download.php?file=01-White-Noise&length=10'")
		# create a card response in the alexa app
    response.set_simple_card("Out of Office App", "Status is in the office.")
		# log the output if needed
    logger.info 'music processed'
		# send a message to slack
    update_status "music"
  end


  on_intent("persist") do
		# add a response to Alexa
    response.set_output_speech_ssml("<speak>Persistent is the key to success!<amazon:effect name='whispered'> Keep at it.I think you did a good job. </amazon:effect></speak>")
		# create a card response in the alexa app
    response.set_simple_card("study with me App", "persist.")
		# log the output if needed
    logger.info 'persist processed'
		# send a message to slack
    update_status "persist"
  end

  on_intent("GONE_HOME") do
		# add a response to Alexa
    response.set_output_speech_text("I've updated your status to GONE_HOME")
		# create a card response in the alexa app
    response.set_simple_card("Out of Office App", "Status is in the office.")
		# log the output if needed
    logger.info 'GONE_HOME processed'
		# send a message to slack
    update_status "GONE_HOME"
  end

  on_intent("DO_NOT_DISTURB") do
    # add a response to Alexa
    response.set_output_speech_text("I've updated your status to DO_NOT_DISTURB")
    # create a card response in the alexa app
    response.set_simple_card("Out of Office App", "Status is in the office.")
    # log the output if needed
    logger.info 'DO_NOT_DISTURB processed'
    # send a message to slack
    update_status "DO_NOT_DISTURB"
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
    update_status "BACK_IN", duration
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

def update_status status, duration = nil

	# gets a corresponding message
  message = get_message_for status, duration
	# posts it to slack
  post_to_slack status, message

end

def get_message_for status, duration

	# Default response
  message = "other/unknown"

	# looks up a message based on the Status provided
  if status == "study_begins"
    message = ENV['APP_USER'].to_s + " starts studying."
  elsif status == "BACK_IN"
    message = ENV['APP_USER'].to_s + " will be back in #{(duration/60).round} minutes"
  elsif status == "studyends"
    message = ENV['APP_USER'].to_s + " can have a rest now"
  elsif status == "GONE_HOME"
    message = ENV['APP_USER'].to_s + " has left for the day. Check back tomorrow."
  elsif status == "DO_NOT_DISTURB"
    message = ENV['APP_USER'].to_s + " is busy. Please do not disturb."
  end

	# return the appropriate message
  message

end

def post_to_slack status_update, message

	# look up the Slack url from the env
  slack_webhook = ENV['SLACK_WEBHOOK']

	# create a formatted message
  formatted_message = "This study round for #{ENV['APP_USER'].to_s} is #{update_status}"
  #formatted_message = "*Status Changed for #{ENV['APP_USER'].to_s} to: #{status_update}*\n"
  formatted_message += "#{message} "

	# Post it to Slack
  HTTParty.post slack_webhook, body: {text: formatted_message.to_s, username: "OutOfOfficeBot", channel: "back" }.to_json, headers: {'content-type' => 'application/json'}

end
