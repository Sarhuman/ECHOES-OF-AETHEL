class_name AethelAudioManager
extends Node
var music_player: AudioStreamPlayer
var sfx_bus: StringName = &"Master"
var music_bus: StringName = &"Master"

func _ready() -> void:
 music_player = AudioStreamPlayer.new()
 music_player.bus = music_bus
 add_child(music_player)

func play_sfx(stream: AudioStream) -> void:
 if stream == null: return
 var voice := AudioStreamPlayer.new()
 voice.bus = sfx_bus
 voice.stream = stream
 add_child(voice)
 voice.finished.connect(voice.queue_free)
 voice.play()

func play_sfx_3d(stream: AudioStream, source: Node3D) -> void:
 if stream == null or source == null: return
 var voice := AudioStreamPlayer3D.new()
 voice.stream = stream
 voice.bus = sfx_bus
 source.add_child(voice)
 voice.finished.connect(voice.queue_free)
 voice.play()

func change_music(stream: AudioStream) -> void:
 if stream == music_player.stream: return
 if music_player.playing:
  var tween := create_tween()
  tween.tween_property(music_player,"volume_db",-40.0,0.5)
  await tween.finished
 music_player.stop()
 music_player.stream = stream
 music_player.volume_db = 0
 if stream != null: music_player.play()
