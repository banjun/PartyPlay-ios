require 'sinatra'

post '/request' do
  p request.body.size
  open('./uploaded.m4a', 'w') do |f|
    f.write(request.body.read)
  end
  200
end
