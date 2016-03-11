require 'sinatra'
require 'sinatra/base'

class App < Sinatra::Base
  get '/' do
    output = `cd .. ; sh run_tests.sh`
    output
  end
end
