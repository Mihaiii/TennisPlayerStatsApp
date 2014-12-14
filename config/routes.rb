Rails.application.routes.draw do
  get '/input' => 'stats#input'
  post '/calcstats' => 'stats#calcstats'
  get '/result' => 'stats#result'
  get '/graf' => 'stats#graf'
end
