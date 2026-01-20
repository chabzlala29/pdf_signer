Rack::Attack.throttle("uploads/ip", limit: 20, period: 1.hour) do |req|
  req.ip if req.path == "/documents"
end
