require 'sinatra'
require 'sinatra/base'
require 'json'
require 'octokit'
require 'git'

class App < Sinatra::Base
  ACCESS_TOKEN = ENV['GITHUB_TOKEN']

  @@output = "No builds started."

  before do
    @client ||= Octokit::Client.new(:access_token => ACCESS_TOKEN)
  end

  get '/' do
    Dir.chdir("public") 
    images = Dir.glob("*.png")
    Dir.chdir("../")
    erb :index, :locals => {:output => @@output, :images => images}
  end

  post '/event_handler' do
    @payload = JSON.parse(params[:payload])

    case request.env['HTTP_X_GITHUB_EVENT']
    when "pull_request"
      if @payload["action"] == "opened"
        process_pull_request(@payload["pull_request"])
      end
    when "push"
      process_push(@payload)
    end
  end

  helpers do
    def process_push(push)
      branch_name = push['ref']
      repo_name = push['repository']['full_name']
      clone_url = "http://www.github.com/" + repo_name + ".git"
      @@output = "Building push to " + branch_name + " at " + repo_name + "<br/>SHA: " + push['after'] + "<br/><br/>"

      `rm public/*`
      `cd .. ; rm -rf yabause`
      g = Git.clone clone_url, "../yabause"
      g.checkout branch_name

      @@output = @@output  + `cd ../script ; sh ci-hook.sh`
      
      @@output.gsub!(/\r?\n/, "<br/>")
    end

    def process_pull_request(pull_request)
      url = "http://example.com"
      context = "GameCI"
      pr1 = pull_request['base']['repo']['full_name']
      sha = pull_request['head']['sha']
      branch_name = pull_request['head']['ref']

      notify = false

      if notify
        @client.create_status(pr1, sha, 'pending',
          {
            target_url: url, 
            description: "Checking game screenshots...", 
            context: context
          })
      end

      @@output = "Building " + pull_request['head']['label'] + " for " + pr1 + "<br/>" + "SHA: " + sha + "<br/><br/>"

      repo_name = pull_request["head"]["repo"]["full_name"]
      clone_url = "http://www.github.com/" + repo_name + ".git"

      `rm public/*`
      `cd .. ; rm -rf yabause`
      g = Git.clone clone_url, "../yabause"
      g.checkout branch_name

      #execute build
      @@output = @@output  + `cd ../script ; sh ci-hook.sh`

      if notify
        if @@output.include? "FAIL"
          @client.create_status(pr1, sha, 'failure', 
            {
              target_url: url, 
              description: "Screenshots didn't match.", 
              context: context
            })
      else
          @client.create_status(pr1, sha, 'success', 
            {
              target_url: url, 
              description: "All game screenshots matched.", 
              context: context
            })
        end
      end

      @@output.gsub!(/\r?\n/, "<br/>")
    end
  end
end
