require "../../spec_helper"

describe EasySubtitle::MkvInfo do
  describe ".parse" do
    it "parses subtitle tracks from mkvmerge JSON" do
      json = read_fixture("mkvmerge_output.json")
      info = EasySubtitle::MkvInfo.parse(json)

      subs = info[:subtitle_tracks]
      subs.size.should eq 3

      subs[0].id.should eq 3
      subs[0].language.should eq "eng"
      subs[0].codec_id.should eq "S_TEXT/UTF8"
      subs[0].default.should be_true
      subs[0].forced.should be_false

      subs[1].id.should eq 4
      subs[1].language.should eq "jpn"
      subs[1].codec_id.should eq "S_TEXT/ASS"
      subs[1].forced.should be_true

      subs[2].id.should eq 5
      subs[2].language.should eq "dut"
    end

    it "parses audio tracks" do
      json = read_fixture("mkvmerge_output.json")
      info = EasySubtitle::MkvInfo.parse(json)

      audio = info[:audio_tracks]
      audio.size.should eq 2

      audio[0].id.should eq 1
      audio[0].language.should eq "eng"
      audio[1].language.should eq "jpn"
    end

    it "wraps invalid mkvmerge json" do
      expect_raises(EasySubtitle::Error, /Invalid mkvmerge JSON output/) do
        EasySubtitle::MkvInfo.parse("{not json")
      end
    end
  end

  describe "SubtitleTrack" do
    it "detects SRT-compatible tracks" do
      track = EasySubtitle::SubtitleTrack.new(
        id: 3, language: "eng", codec: "SubRip/SRT",
        codec_id: "S_TEXT/UTF8"
      )
      track.srt_compatible?.should be_true
      track.ass?.should be_false
      track.extractable?.should be_true
    end

    it "detects ASS tracks" do
      track = EasySubtitle::SubtitleTrack.new(
        id: 4, language: "jpn", codec: "SubStationAlpha",
        codec_id: "S_TEXT/ASS"
      )
      track.srt_compatible?.should be_false
      track.ass?.should be_true
      track.extractable?.should be_true
    end
  end
end
