require 'midilib/sequence'
require 'midilib/consts'
include MIDI

seq = Sequence.new()

notes = [
  0, 0, 0, 2, 2, 2, 3, 3,  3, 5, 5, 5, 7, 7, 10, 10,
  *[0, 0, 0, 2, 2, 2, 3, 3,  3, 5, 5, 5, 7, 7, 10, 10].map { |x| x + 12 }
]
notes = notes.shuffle(random: Random.new(2))
p notes

def merge_sort(a, o = [])
  return a if a.length <= 1
  mid = a.length / 2
  left = merge_sort(a.take(mid), o)
  right = merge_sort(a.drop(mid), o)
  return merge(left, right, [], o)
end

def merge(left, right, result, o)
  return result if left.empty? && right.empty?
  candidate = []
  if right.empty? || (!left.empty? && left[0] <= right[0])
    o << left[0]
    return merge(left[1..-1], right, [*result, left[0]], o)
  else
    o << right[0]
    return merge(left, right[1..-1], [*result, right[0]], o)
  end
end

o = []
result = merge_sort(notes, o)
raise "wrong: #{result}" unless result == notes.sort
notes += o

track = Track.new(seq)
seq.tracks << track
track.events << Tempo.new(Tempo.bpm_to_mpq(120))
track.events << MetaEvent.new(META_SEQ_NAME, 'Sequence Name')

track = Track.new(seq)
seq.tracks << track

track.name = 'My New Track'
track.instrument = GM_PATCH_NAMES[0]

quarter_note_length = seq.note_to_delta('quarter')
notes.each do |offset|
  track.events << NoteOn.new(0, 64 + offset - 5, 127, 0)
  track.events << NoteOff.new(0, 64 + offset - 5, 127, quarter_note_length / 4)
end

# Calling recalc_times is not necessary, because that only sets the events'
# start times, which are not written out to the MIDI file. The delta times are
# what get written out.

# track.recalc_times

File.open('gen.mid', 'wb') { |file| seq.write(file) }