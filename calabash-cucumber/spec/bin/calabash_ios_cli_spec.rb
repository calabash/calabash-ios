describe 'Command Line Interface' do

  it 'reports the calabash-ios version' do
    # Reproduces the dread 'minitest' bug using $ calabash-ios version
    Open3.popen3('calabash-ios version') do  |_, stdout,  stderr, _|
      out = stdout.read.strip
      err = stderr.read.strip
      expect(err).to be == ''
      out_tokens = out.split(/\s/)
      expect(out_tokens.count).to be == 1
      expect(out_tokens.first =~ /(\d+\.\d+\.\d+)(\.pre\d+)?/).to be_truthy
    end
  end

  it 'can exit the console the console cleanly' do
    # Reproduces the dread 'minitest' bug when exiting the console
    Open3.popen3('sh') do |stdin, _, stderr, _|
      stdin.puts 'calabash-ios console <<EOF'
      stdin.puts 'exit'
      stdin.puts 'EOF'
      stdin.close
      err = stderr.read.strip
      expect(err).to be == ''
    end
  end

  it 'awesome-print monkey-patch in run-loop is applied' do
    # Make sure run-loop has the patch applied.
    Open3.popen3('sh') do |stdin, stdout, stderr, _|
      stdin.puts 'IRBRC=../scripts/.irbrc bundle exec irb <<EOF'
      stdin.puts "require 'run_loop'"
      stdin.puts "foo = RunLoop::Version.new('9.9.9')"
      stdin.puts 'EOF'
      stdin.close
      out = stdout.read.strip
      err = stderr.read.strip
      expect(out[/Error: undefined method `major' for/,0]).to be == nil
      expect(out[/Error:/,0]).to be == nil
      expect(err).to be == ''
    end
  end
end
