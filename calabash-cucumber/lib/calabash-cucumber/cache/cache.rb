module Calabash
  module Cucumber

    # @!visibility private
    # A class for managing an on-disk cache.
    class Cache

      require 'fileutils'

      # Creates a new cache backed by file at `path`.
      #
      # @param [String] path The file to store the cache. If this
      #  path does not exist, it and any subdirectories will be created
      #  when the first call to `write` is made.
      def initialize(path)
        @path = path
      end

      # @!visibility private
      def to_s
        "Cache: #{path}"
      end

      # @!visibility private
      #
      # Clears the current cache and writes the `default_cache`.
      def clear
        write(default_cache)
      end

      # Reads the current cache.
      #
      # If the cache does not exist it will be created.
      #
      # @return [Hash] A hash representation of the cache on disk.
      def read
        if File.exist?(path)
          File.open(path, "r:UTF-8") do |file|
            Marshal.load(file)
          end
        else
          write(default_cache)
        end
      end

      # @!visibility private
      #
      # If no cache exists or the cache is cleared, this will be the default
      # hash that is written.
      def default_cache
        {}
      end

      private

      attr_reader :path

      # @!visibility private
      #
      # Writes `hash` as a serial object.  The existing data is overwritten.
      #
      # @param [Hash] hash The hash to write.
      # @raise [ArgumentError] The `hash` parameter must not be nil and it must
      #  be a Hash.
      # @raise [TypeError] If the hash contains objects that cannot be written
      #  by Marshal.dump.
      #
      # @return [Hash] Returns the `hash` argument.
      def write(hash)
        if hash.nil?
          raise ArgumentError, 'Expected the hash parameter to be non-nil'
        end

        unless hash.is_a?(Hash)
          raise ArgumentError, "Expected #{hash} to a Hash, but it is a #{hash.class}"
        end

        directory = File.dirname(path)
        unless File.exist?(directory)
          FileUtils.mkdir_p(directory)
        end

        File.open(path, "w:UTF-8") do |file|
          Marshal.dump(hash, file)
        end
        hash
      end
    end
  end
end

