class_name AethelAudioManager
extends Node
## Existing audio service, shared by the world. Original synthetic placeholders only.
const BUSES := ["Music","SFX","UI","Ambience"]
static var cue_cache: Dictionary = {}
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_bus: StringName = &"SFX"
var music_bus: StringName = &"Music"
var cooldowns: Dictionary = {}
var played_cues: Dictionary = {}
var active_voices := 0

static func ensure_buses() -> void:
 for bus: String in BUSES:
  if AudioServer.get_bus_index(bus) >= 0: continue
  AudioServer.add_bus()
  var index := AudioServer.bus_count-1
  AudioServer.set_bus_name(index,bus)
  AudioServer.set_bus_send(index,"Master")

func _ready() -> void:
 ensure_buses()
 music_player = AudioStreamPlayer.new()
 music_player.bus = music_bus
 add_child(music_player)
 ambience_player = AudioStreamPlayer.new()
 ambience_player.bus = &"Ambience"
 add_child(ambience_player)

func play_sfx(stream: AudioStream) -> void:
 _voice(stream,sfx_bus)

func _voice(stream: AudioStream,bus: StringName) -> void:
 if stream == null or active_voices >= 8: return
 var voice := AudioStreamPlayer.new()
 voice.bus = bus
 voice.stream = stream
 add_child(voice)
 active_voices += 1
 voice.finished.connect(func() -> void: active_voices = maxi(0,active_voices-1); voice.queue_free())
 voice.play()

func play_cue(id: String,ui: bool = false) -> void:
 var frequencies := {"attack":220,"hit":180,"hurt":120,"heal":520,"skill":600,"pickup":680,"inventory":400,"trade":740,"npc":440,"chest":300,"anchor":880,"level":980,"death":90,"buff":480,"ui":500,"rare":820,"elite":750,"drop":320}
 if not frequencies.has(id): id = "ui" if ui else "drop"
 var now := Time.get_ticks_msec()/1000.0
 if now < float(cooldowns.get(id,0)): return
 cooldowns[id] = now + (0.12 if id in ["hit","hurt","attack"] else 0.2)
 if not cue_cache.has(id):
  var stream := AudioStreamWAV.new()
  stream.format = AudioStreamWAV.FORMAT_16_BITS
  stream.mix_rate = 22050
  var bytes := PackedByteArray()
  bytes.resize(4410)
  for i in range(2205):
   var amplitude := sin(TAU*float(frequencies[id])*i/22050.0)*1300*(1.0-i/2205.0)
   bytes.encode_s16(i*2,roundi(amplitude))
  stream.data = bytes
  cue_cache[id] = stream
 _voice(cue_cache[id],&"UI" if ui else sfx_bus)
 played_cues[id] = int(played_cues.get(id,0))+1

func play_sfx_3d(stream: AudioStream,source: Node3D) -> void:
 if stream == null or source == null: return
 var voice := AudioStreamPlayer3D.new()
 voice.bus = sfx_bus
 voice.stream = stream
 source.add_child(voice)
 voice.finished.connect(voice.queue_free)
 voice.play()

func change_music(stream: AudioStream) -> void:
 if stream == music_player.stream: return
 music_player.stop()
 music_player.stream = stream
 if stream != null: music_player.play()

func change_ambience(stream: AudioStream) -> void:
 ambience_player.stop()
 ambience_player.stream = stream
 if stream != null: ambience_player.play()
