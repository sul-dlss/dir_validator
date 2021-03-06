require 'spec_helper'

describe("Integration tests: SOHP example", :integration => true) do

  it "should get the expected warnings" do

    # Run the validations.
    dv = DirValidator.new(fixture_item(:sohp))
    dv.dirs('druid_dir', :re => /^(\w{11})$/, :n  => '1+').each do |dir|
      # Store the DRUID.
      druid = dir.basename

      # Assert existence of the preCM file.
      dir.file('preCM', :name => 'preContentMetadata.xml')

      # Assert existince of the top-level subdirs, and store them for later use.
      img = dir.dir('Images', :name => 'Images')
      pm  = dir.dir('PM',     :name => 'PM')
      sl  = dir.dir('SL',     :name => 'SL')
      sh  = dir.dir('SH',     :name => 'SH')

      # Assert existence of the content of the Images subdir.
      # We also store part of their file name for later use (druid_n).
      druid_n = nil
      img.files('Images-jpg', :re => /^(#{druid}_\d+)_img_(\d+).jpg$/).each do |f|
        druid_n = f.match_data[1]
        img.file('Images-md5', :name => f.basename + '.md5')
      end

      # Assert the existence of the content of the PM subdir, and
      # of files in other subdirs having parallel names.
      pm.files('PM-wav', :re => /^(#{druid_n}_\w+)_pm.wav$/).each do |f|
        prefix = f.match_data[1]
        pm.file('PM-md5',     :name => f.basename + '.md5')
        sl.file('SL-mp3',     :name => prefix + '_sl.mp3')
        sl.file('SL-mp3-md5', :name => prefix + '_sl.mp3.md5')
        sl.file('SL-techmd',  :name => prefix + '_sl_techmd.xml')
        sh.file('SH-wav',     :name => prefix + '_sh.wav')
        sh.file('SH-md5',     :name => prefix + '_sh.wav.md5')
      end
    end

    # Make sure we got the expected warnings.
    extra = DirValidator::Validator::EXTRA_VID
    dv.validate
    dv.warnings.map { |w| [w.vid, w.opts] }.should == [
      ["SL-techmd", {:got=>0, :base_dir=>"cc000cc0003/SL", :n=>"1", :name=>"cc000cc0003_181_a_sl_techmd.xml"}],
      ["SL-techmd", {:got=>0, :base_dir=>"cc000cc0003/SL", :n=>"1", :name=>"cc000cc0003_181_b_sl_techmd.xml"}],
      [extra,       {:path=>"aa000aa0001/Transcript"}],
      [extra,       {:path=>"aa000aa0001/Transcript/aa000aa0001.pdf"}],
    ]
  end

end
