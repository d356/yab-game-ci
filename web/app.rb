require 'sinatra'
require 'sinatra/base'
require 'json'
require 'octokit'

class App < Sinatra::Base
  ACCESS_TOKEN = ENV['GITHUB_TOKEN']

  @@output = "No builds started."

  before do
    @client ||= Octokit::Client.new(:access_token => ACCESS_TOKEN)
  end

  get '/' do
    erb :index, :locals => {:output => @@output}
  end

  post '/event_handler' do
    @payload = JSON.parse(params[:payload])

    case request.env['HTTP_X_GITHUB_EVENT']
    when "pull_request"
      if @payload["action"] == "opened"
        process_pull_request(@payload["pull_request"])
      end
    end
  end

  helpers do
    def process_pull_request(pull_request)
      @url = "http://example.com"
      @context = "GameCI"
      @pr1 = pull_request['base']['repo']['full_name']
      @pr2 = pull_request['head']['sha']

      @client.create_status(@pr1, @pr2, 'pending',
        {
          target_url: @url, 
          description: "Checking game screenshots...", 
          context: @context
        })

      @@output = "Building " + @pr1 + " at " + @pr2 + "<br/><br/>"

      #execute build
      @@output = @@output  + `cd ../script ; sh ci-hook.sh`

      if @@output.include? "FAIL"
        @client.create_status(@pr1, @pr2, 'failure', 
          {
            target_url: @url, 
            description: "Screenshots didn't match.", 
            context: @context
          })
      else
        @client.create_status(@pr1, @pr2, 'success', 
          {
            target_url: @url, 
            description: "All game screenshots matched.", 
            context: @context
          })
      end

      @@output.gsub!(/\r?\n/, "<br/>")
    end
  end
end
