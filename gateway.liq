#!/usr/bin/liquidsoap

# Settings for the streaming server engine
set("harbor.bind_addrs", ["0.0.0.0"])
set("log.stdout", true)

# 1. Open an input port to accept incoming worker stream connections
# This creates an endpoint at rtmp://your-gateway:8080/live/jazz
gateway_receiver = input.harbor.dynamic(
  port=8080, 
  "/live/jazz", 
  password="super_secret_baton_pass_password"
)

# 2. Local Emergency Fallback (If no worker is connected)
# Ensure these paths exist on your Render disk space
emergency_music = playlist("/workspace/emergency_music/")
emergency_video = single("/workspace/emergency_background.mp4")
emergency_backup = mux.video(video=emergency_video, emergency_music)

# 3. Dynamic Switch Logic
# 'track_sensitive=true' forces the system to wait for a track boundary (end of a song) 
# before executing a handoff, keeping the transition completely seamless.
final_feed = fallback(track_sensitive=true, [gateway_receiver, emergency_backup])

# 4. Expose an HTTP status endpoint for our Supervisor Health Check
def stream_status(req, res) =
  is_connected = source.is_up(gateway_receiver)
  res.json({ "worker_connected": is_connected })
end
harbor.http.register(port=8080, method="GET", "/status", stream_status)

# 5. Continuous Output Broadcast directly to YouTube Live
output.gstreamer.rtmp(
  id="youtube_live_stream",
  url="rtmp://a.rtmp.youtube.com/live2/YOUR_YOUTUBE_STREAM_KEY",
  final_feed
)