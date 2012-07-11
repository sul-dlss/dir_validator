require 'spec_helper'

describe DirValidator::Item do

  def new_item(path, catalog_id = nil)
    return DirValidator::Item.new(nil, path, catalog_id)
  end

  it "can initialize a Item" do
    new_item('.').should be_kind_of DirValidator::Item
  end

  it "should have set path-related attributes correctly" do
    itm = new_item('./foo/bar/fubb/../.././blah.txt')
    itm.instance_variable_get('@pathname').should be_kind_of Pathname
    itm.path.should == 'foo/blah.txt'  # Path should be normalized.
    itm.basename.should == 'blah.txt'  # Can get basename.
  end

  it "should set catalog_id if given, otherwise nil" do
    new_item('foo').catalog_id.should == nil
    new_item('foo', 987).catalog_id.should == 987
  end

  it "should set filetype-related attributes correctly" do
    # A dir.
    itm = new_item(Tempfile.new('item_spec_').path)
    itm.filetype.should    == :file
    itm.is_file.should == true
    itm.is_dir.should  == false
    # A dir.
    itm = new_item('.')
    itm.filetype.should    == :dir
    itm.is_file.should == false
    itm.is_dir.should  == true
  end

  it "basename() should support a suffix argument" do
    itm = new_item('foo/bar.rb')
    itm.basename.should == 'bar.rb'
    itm.basename('.rb').should == 'bar'
  end

  it "target_match() should return MatchData and store it for later use" do
    itm = new_item('.')
    itm.target = 'aabb'
    m = itm.target_match(/(a+)(b+)/)
    m[0].should == 'aabb'
    m[1].should == 'aa'
    itm.match_data.should be_kind_of MatchData
    itm.match_data[2].should == 'bb'
  end

  it "target_match() should return nil if the match fails" do
    itm = new_item('.')
    itm.target = 'zzzz'
    m = itm.target_match(/a/)
    m.should == nil
    itm.match_data.should == nil
  end

  describe "can call validation methods on Item objects" do

    before(:each) do
      # Setup params for the double and stubbed method.
      @dv   = double('dir_validator')
      @path = '.'
      @vid  = 'foo-validation'
      @opts = {:a => 1, :b => 2}
      @exp  = [1,2,3]
    end

    it "dirs()" do
      hi = hash_including(:base_dir => @path)
      @dv.should_receive(:dirs).with(@vid, hi).and_return(@exp)
      DirValidator::Item.new(@dv, @path).dirs(@vid, @opts).should == @exp
    end

    it "files()" do
      hi = hash_including(:base_dir => @path)
      @dv.should_receive(:files).with(@vid, hi).and_return(@exp)
      DirValidator::Item.new(@dv, @path).files(@vid, @opts).should == @exp
    end

    it "dir()" do
      hi = hash_including(:n => '1', :base_dir => @path)
      @dv.should_receive(:dirs).with(@vid, hi).and_return(@exp)
      DirValidator::Item.new(@dv, @path).dir(@vid, @opts).should == @exp
    end

    it "file()" do
      hi = hash_including(:n => '1', :base_dir => @path)
      @dv.should_receive(:files).with(@vid, hi).and_return(@exp)
      DirValidator::Item.new(@dv, @path).file(@vid, @opts).should == @exp
    end

  end

  describe "item_opts() should return expected hash" do

    before(:each) do
      @opts  = {:aaa => 111, :bbb => 222}
      @other = {:ccc => 333, :ddd => 444}
    end

    it "directory: base_dir = Item.path" do
      itm = new_item('foo/bar')
      itm.instance_variable_set('@filetype', :dir)
      exp = {:base_dir => itm.path}
      itm.item_opts(@opts).should == @opts.merge(exp)
      itm.item_opts(@opts, @other).should == @opts.merge(@other).merge(exp)
    end

    it "file with a parent dir: base_dir = Item.dirname" do
      itm = new_item('foo/bar.txt')
      itm.instance_variable_set('@filetype', :file)
      exp = {:base_dir => 'foo'}
      itm.item_opts(@opts).should == @opts.merge(exp)
      itm.item_opts(@opts, @other).should == @opts.merge(@other).merge(exp)
    end

    it "file without a parent dir: no base_dir" do
      itm = new_item('bar.txt')
      itm.instance_variable_set('@filetype', :file)
      itm.item_opts(@opts).should == @opts
      itm.item_opts(@opts, @other).should == @opts.merge(@other)
    end

  end

end
