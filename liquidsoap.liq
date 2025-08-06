#!/usr/bin/liquidsoap

settings.server.telnet := true
settings.server.telnet.bind_addr := "0.0.0.0"
settings.server.telnet.port := 1234

settings.log.level := 2
settings.log.stdout := true

icecast_host = environment.get("ICECAST_HOST")
icecast_port = int_of_string(environment.get("ICECAST_PORT"))
icecast_mount = environment.get("ICECAST_MOUNT")
icecast_password = environment.get("ICECAST_PASSWORD")

station_name = environment.get("STATION_NAME")
station_description = environment.get("STATION_DESCRIPTION")
station_genre = environment.get("STATION_GENRE")
station_url = environment.get("STATION_URL")

# GLOBAL VARS
current_title = ref("Unknown Title")
current_artist = ref("Unknown Artist")
current_image = ref("")

tracks = playlist(
  mode="randomize",
  reload_mode="watch",
  "/app/storage/tracklist.m3u"
)

tracks = blank.skip(max_blank=5.0, min_noise=0.01, tracks)
tracks = normalize(tracks)
tracks = compress(tracks)

tracks = metadata.map(update=false, fun(m) -> begin
  title = m["title"] ?? "Unknown Title"
  artist = m["artist"] ?? "Unknown Artist"
  filename = m["filename"] ?? "Unknown File"

  cover_url := ""

  current_title := title
  current_artist := artist
  current_image := cover_url

  list.append(m, [("StreamUrl", cover_url)])

  log("Playing track: #{artist} - #{title} (#{filename})")
  m
end, tracks)

jingles = playlist(
  mode="randomize",
  reload_mode="watch",
  "/app/storage/jinglelist.m3u"
)

jingles = blank.skip(max_blank=5.0, min_noise=0.01, jingles)
jingles = normalize(jingles)
jingles = compress(jingles)

jingles = metadata.map(update=false, fun(m) -> begin
  title = m["title"] ?? "Jingle"
  artist = m["artist"] ?? station_name
  filename = m["filename"] ?? "Unknown Jingle"
  log("Playing jingle: #{artist} - #{title} (#{filename})")
  m
end, jingles)

main_source = rotate(
  weights=[1, 1],
  [tracks, jingles]
)

main_source = crossfade(
  duration=1.0,
  fade_in=0.5,
  fade_out=0.5,
  main_source
)

safe_source = fallback(
  track_sensitive=false,
  [
    main_source,
    sine(440.0)
  ]
)

safe_source = metadata.insert(
  every=3.0,
  fun() -> [
    ("title", !current_title),
    ("artist", !current_artist),
    ("StreamUrl", !current_image)
  ],
  safe_source
)

output.icecast(
  %mp3(bitrate=128, samplerate=44100, stereo=true),
  host=icecast_host,
  port=icecast_port,
  password=icecast_password,
  mount=icecast_mount,
  name=station_name,
  description=station_description,
  genre=station_genre,
  url=station_url,
  safe_source
)
