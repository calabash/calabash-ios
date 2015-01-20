require 'xcodeproj'
require 'pry'


module Calabash
	module Setup
		class CBInitializer

			@@CFNETWORK = "CFNetwork.framework"
			@@CFNETWORK_PATH = "/System/Library/Frameworks/#{@@CFNETWORK}"

			@@CALABASH = "calabash.framework"

			def initialize(xcodeproj)

				@xcode_proj = Xcodeproj::Project.new(xcodeproj)
				@xcode_proj.initialize_from_file
				
				if( @xcode_proj.targets.length < 1)
					raise Exception.new("No targets found in #{pbxPath}")
				end
			end


			def find_target(defaultProjectName)

				default_target = nil

				if(@xcode_proj.targets.length  == 1)
					@default_target = @xcode_proj.targets.first
				 else

				 	target_name = ENV["TARGET"]

				 	if target_name.nil?
				 		default_target_name = defaultProjectName
				 	end

					@xcode_proj.targets.each do |target|
						
						if target.name.eql?(default_target_name)
							default_target = target
						end
					end
			
					if ENV["TARGET"].nil? 
				
						msg("Info") do
							puts "Found several targets. Please enter name of target to duplicate."
						end

						if default_target
							puts "Default target: #{default_target.name}. Just hit <Enter> to select default"
						end


						@xcode_proj.targets.each do |target|
							puts "#{target.name}"
						end

						input_string = STDIN.gets.chomp
						puts "input: #{input_string}"

						if default_target and input_string.length == 0
							puts "Selecting default target #{default_target.name}"
						else

							default_target = nil
							@xcode_proj.targets.each do |target|

								if target.name.eql?(input_string)
									default_target = target
									break
								end
							end
						end
					end
				end


				#Last
				if default_target.nil?
					puts "No target was selected"
					return nil
				end


				return default_target
			end

			def setup(defaultProjectName)
				#Search for existing target
				target = find_target(defaultProjectName)

				if target.nil?
					puts "No target was selected. Aborting."
					return
				end

				dup_target = Xcodeproj::Project::ProjectHelper.new_target(target.project, :application, "#{target.name}-cal",:ios,
					target.deployment_target, target.project.products_group)

				frameworks_group = @xcode_proj.frameworks_group

				cfnetwork_reference = frameworks_group.find_subpath(@@CFNETWORK)
				if cfnetwork_reference.nil?
					frameworks_group.new_reference(@@CFNETWORK_PATH)
				end

				calabash_reference = frameworks_group.find_subpath(@@CALABASH)
				if calabash_reference.nil?
					frameworks_group.new_reference(@@CALABASH)
				end

				dup_target.frameworks_build_phase.add_file_reference(cfnetwork_reference)
				dup_target.frameworks_build_phase.add_file_reference(calabash_reference)

				@xcode_proj.save


				return true
			end
		end
	end
end