class Resources

  def self.shared
    @resources ||= Resources.new
  end

  def travis_ci?
    @travis_ci ||= ENV['TRAVIS'].to_s == 'true'
  end

  def resources_dir
    @resources_dir = File.expand_path(File.join(File.dirname(__FILE__),  'resources'))
  end

  def app_bundle_path(bundle_name)
    case bundle_name
      when :lp_simple_example
        return @lp_cal_app_bundle_path ||= File.join(self.resources_dir, 'enable-accessibility', 'LPSimpleExample-cal.app')
      when :chou
        return @chou_app_bundle_path ||= File.join(self.resources_dir, 'chou.app')
      else
        raise "unexpected argument '#{bundle_name}'"
    end
  end
end
