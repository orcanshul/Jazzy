#!/usr/bin/liquidsoap

set("harbor.bind_addrs", ["0.0.0.0"])
set("log.stdout", true)

# Open an optimized pipeline receiver to catch incoming worker stream audio/video arrays
gateway_receiver = input.harbor.dynamic(
  port=8080, 
  "/live/jazz", 
  password=environment.get("PASSWORD", default="fallback_secure_password")
)

# Provide a simple text fallback loop if all remote worker sources disappear
emergency_backup = single("/workspace/emergency_background.mp4")

# Fall back dynamically on track transitions to eliminate streaming drops on YouTube
final_feed = fallback(track_sensitive=true, [gateway_receiver, emergency_backup])

# Expose a basic low-memory HTTP endpoint for anti-idling and validation checkups
def stream_status(req, res) =
  is_connected = source.is_up(gateway_receiver)
  res.json({ "worker_connected": is_connected })
end
harbor.http.register(port=8080, method="GET", "/status", stream_status)

# Stream direct pass-through FLV metadata to YouTube
output.rtmp(
  url="rtmp://a.rtmp.youtube.com/live2/#{environment.get('YOUR_YOUTUBE_STREAM_KEY')}",
  final_feed
)