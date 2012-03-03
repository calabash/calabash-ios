require 'net/http/persistent'
require 'json'

if not Object.const_defined?(:CALABASH_COUNT)
  #compatability with IRB
  CALABASH_COUNT = {:step_index => 0, :step_line => "irb"}
end




module Calabash module Cucumber

module Operations

  DATA_PATH = File.expand_path(File.dirname(__FILE__))

  def macro(txt)
    if self.respond_to?:step
      step(txt)
    else
      Then txt
    end
  end

  def wait_for(timeout, &block)
    begin
      Timeout::timeout(timeout) do
        until block.call
          sleep 0.3
        end
      end
    rescue Exception => e
      screenshot_and_raise e
    end
  end

  def query(uiquery, *args)
    map(uiquery, :query, *args)
  end

  def label(uiquery)
    query(uiquery, :accessibilityLabel)
  end

  def screenshot_and_raise(msg)
    screenshot
    sleep 5
    raise(msg)
  end

  def touch(uiquery,options={})
    options[:query] = uiquery
    views_touched = playback("touch",options)
    screenshot_and_raise "could not find view to touch: '#{uiquery}', args: #{args}" if views_touched.empty?
    views_touched
  end

  def simple_touch(label,*args)
    touch("view marked:'#{label}'", *args)
  end

  def tap(label,*args)
    simple_touch(label,*args)
  end

  def ok
    touch("view marked:'ok'")
  end

  def set_text(uiquery, txt)
    text_fields_modified = map(uiquery, :setText, txt)
    screenshot_and_raise "could not find text field #{uiquery}" if text_fields_modified.empty?
    text_fields_modified
  end


  def swipe(dir,options={})
    playback("swipe_#{dir}",options)
  end

  def cell_swipe(options={})
    playback("cell_swipe",options)
  end

  def done
    map(nil,:touchDone,load_playback_data("touch_done"))
  end

  def scroll(uiquery,direction)
    views_touched=map(uiquery, :scroll, direction)
    screenshot_and_raise "could not find view to scroll: '#{uiquery}', args: #{direction}" if views_touched.empty?
    views_touched
  end

  def scroll_to_row(uiquery,number)
    views_touched=map(uiquery, :scrollToRow, number)
    screenshot_and_raise "could not find view to scroll: '#{uiquery}', args: #{number}" if views_touched.empty?
    views_touched
  end

  def pinch(in_out,options={})
    file = "pinch_in"
    if in_out.to_sym==:out
      file = "pinch_out"
    end
    playback(file, options)
  end

  def rotate(dir)
    @current_rotation = @current_rotation || :down
    rotate_cmd = nil
    case dir
      when :left then
        if @current_rotation == :down
          rotate_cmd = "left_home_down"
          @current_rotation = :right
        elsif @current_rotation == :right
          rotate_cmd = "left_home_right"
          @current_rotation = :up
        elsif @current_rotation == :left
          rotate_cmd = "left_home_left"
          @current_rotation = :down
        elsif @current_rotation == :up
          rotate_cmd = "left_home_up"
          @current_rotation = :left
        end
      when :right then
        if @current_rotation == :down
          rotate_cmd = "right_home_down"
          @current_rotation = :left
        elsif @current_rotation == :left
          rotate_cmd = "right_home_left"
          @current_rotation = :up
        elsif @current_rotation == :right
          rotate_cmd = "right_home_right"
          @current_rotation = :down
        elsif @current_rotation == :up
          rotate_cmd = "right_home_up"
          @current_rotation = :right
        end
    end

    if rotate_cmd.nil?
      screenshot_and_raise "Does not support rotating #{dir} when home button is pointing #{@current_rotation}"
    end
    playback("rotate_#{rotate_cmd}")
  end

  def background(secs)
    res = http({:method=>:post, :path=>'background'}, {:duration => secs})
  end

  def element_exists(uiquery)
    !query(uiquery).empty?
  end

  def view_with_mark_exists(expected_mark)
    element_exists( "view marked:'#{expected_mark}'" )
  end

  def check_element_exists( query )
    if not element_exists( query )
      screenshot_and_raise "No element found for query: #{query}"
    end
  end

  def check_element_does_not_exist( query )
    if not element_exists( query ).should be_false
      screenshot_and_raise "Expected no elements to match query: #{query}"
    end
  end

  def check_view_with_mark_exists(expected_mark)
    check_element_exists( "view marked:'#{expected_mark}'" )
  end

  # a better name would be element_exists_and_is_not_hidden
  def element_is_not_hidden(uiquery)
     matches = query(uiquery, 'isHidden')
     matches.delete(true)
     !matches.empty?
  end


  def load_playback_data(recording,options={})
    os = options["OS"] || ENV["OS"]
    device = options["DEVICE"] || ENV["DEVICE"]

    rec_dir = ENV['PLAYBACK_DIR'] || "#{Dir.pwd}/playback"
    if !recording.end_with?".base64"
       recording = "#{recording}_#{os}_#{device}.base64"
    end
    data = nil
    if (File.exists?(recording))
      data = File.read(recording)
    elsif (File.exists?("features/#{recording}"))
      data = File.read("features/#{recording}")
    elsif (File.exists?("#{rec_dir}/#{recording}"))
      data = File.read("#{rec_dir}/#{recording}")
    elsif (File.exists?("#{DATA_PATH}/resources/#{recording}"))
      data = File.read("#{DATA_PATH}/resources/#{recording}")
    else
      screenshot_and_raise "Playback not found: #{recording} (searched for #{recording} in #{Dir.pwd}, #{rec_dir}, #{DATA_PATH}/resources"
    end
    data
  end
  def playback(recording, options={})
    data = load_playback_data(recording)

    post_data = %Q|{"events":"#{data}"|
    post_data<< %Q|,"query":"#{options[:query]}"| if options[:query]
    post_data<< %Q|,"offset":#{options[:offset].to_json}| if options[:offset]
    post_data<< %Q|,"reverse":#{options[:reverse]}| if options[:reverse]
    post_data<< %Q|,"prototype":"#{options[:prototype]}"| if options[:prototype]
    post_data << "}"

    res = http({:method=>:post, :raw=>true, :path=>'play'}, post_data)

    res = JSON.parse( res )
    if res['outcome'] != 'SUCCESS'
      screenshot_and_raise "playback failed because: #{res['reason']}\n#{res['details']}"
    end
    res['results']
  end

  def record_begin
    http({:method=>:post, :path=>'record'}, {:action => :start})
  end

  def record_end(file_name)
    res = http({:method=>:post, :path=>'record'}, {:action => :stop})
    File.open("_recording.plist",'wb') do |f|
        f.write res
    end
    file_name = "#{file_name}_#{ENV['OS']}_#{ENV['DEVICE']}.base64"
    system("/usr/bin/plutil -convert binary1 -o _recording_binary.plist _recording.plist")
    system("openssl base64 -in _recording_binary.plist -out #{file_name}")
    system("rm _recording.plist _recording_binary.plist")
    file_name
  end

  #def screencast_begin
  #   http({:method=>:post, :path=>'screencast'}, {:action => :start})
  #end
  #
  #def screencast_end(file_name)
  #  res = http({:method=>:post, :path=>'screencast'}, {:action => :stop})
  #  File.open(file_name,'wb') do |f|
  #      f.write res
  #  end
  #  file_name
  #end

  def screenshot
    if ENV['UUID'] && !/localhost/.match(ENV['DEVICE_ENDPOINT'])
      f = %x[idevicescreenshot -u #{ENV['UUID']}]
      line=f.strip().split("\n").last
      filename=line.split(" ").last
      outfile = "#{ENV['SCREENSHOT_PATH_PREFIX']}_#{CALABASH_COUNT[:step_line]}.png"
      if File.exist?filename
        puts "converting screenshot: #{filename} to #{outfile}"
        system("convert #{filename} #{outfile}")
      else
        raise "Error. Unable to screenshot for device #{ENV['UUID']}."
      end
    else
      res = http({:method =>:get, :path => 'screenshot'})
      path = "screenshot_#{CALABASH_COUNT[:step_line]}.png"
      File.open(path,'wb') do |f|
        f.write res
      end
      puts "Saved screenshot: #{path}"
    end
  end
  
  def map( query, method_name, *method_args )
    operation_map = {
      :method_name => method_name,
      :arguments => method_args
    }
    res = http({:method=>:post, :path=>'map'},
                {:query => query, :operation => operation_map})
    res = JSON.parse(res)
    if res['outcome'] != 'SUCCESS'
      screenshot_and_raise "map #{query}, #{method_name} failed because: #{res['reason']}\n#{res['details']}"
    end

    res['results']
  end

  def http(options, data=nil)
    url = url_for(options[:path])
    if options[:method] == :post
      req = Net::HTTP::Post.new url.path
      if options[:raw]
        req.body=data
      else
        req.body = data.to_json
      end

    else
      req = Net::HTTP::Get.new url.path
    end
    make_http_request( url, req )
  end


  def url_for( verb )
    url = URI.parse (ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/")
    url.path = '/'+verb
    url
  end

  def make_http_request( url, req )
    @http = Net::HTTP.new(url.host, url.port)
    res = @http.start do |sess|
      sess.request req
    end
    body = res.body
    begin
      @http.finish if @http and @http.started?
    rescue Exception => e
      puts "Finish #{e}"
    end
    body
  end

end


end end
