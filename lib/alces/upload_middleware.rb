#==============================================================================
# Copyright (C) 2007-2013 Stephen F Norledge & Alces Software Ltd.
#
# This file is part of Alces Upload Middleware, part of the Symphony suite.
#
# Alces Users is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#                                                                               
# You should have received a copy of the GNU Affero General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.
#
# Some rights reserved, see LICENSE.txt.
#==============================================================================
require 'tmpdir' # Needed in 1.8.7 to access Dir::tmpdir

module Alces
  class UploadMiddleware < Struct.new(:app, :frequency,
                                      :input, :pos, :seen, :content_length,
                                      :mtime)
    NULL_LOGGER = Object.new.tap do |o|
      class << o
        def method_missing(s,*a,&b); end
      end
    end

    def initialize(app, opts = {})
      super(app,
            opts[:frequency] || 1)
      @paths = opts[:paths]
      @explicit = opts[:explicit]
      @tmpdir = opts[:tmpdir] || Dir::tmpdir
      @paths = [@paths] if @paths.kind_of?(String)
      @targets_class = opts[:targets_class]
      @logger = opts[:logger] || NULL_LOGGER
      @origins = opts[:origins] || '*'
    end

    def call(env)
      if kick_in?(env)
        # benefit curl users...
        /\A100-continue\z/i =~ env['HTTP_EXPECT'] and return [ 100, {}, [] ]

        length = env["CONTENT_LENGTH"] and length = length.to_i
        chunked = env["TRANSFER_ENCODING"] =~ %r{\Achunked\z}i and length = nil

        if chunked || (length && length > 0)
          return dup._call(env, length)
        end
      end
      app.call(env).tap do |a|
        status, headers, response = a
        if kick_in?(env)
          headers.merge!({'Access-Control-Allow-Origin' => @origins})
        end
      end
    end

    def _call(env, length)
      self.mtime = self.pos = self.seen = 0
      self.input = env["rack.input"]
      env["rack.input"] = self
      self.content_length = length
      convert_and_pass_on(env)
    end

    def _incr(nr)
      self.pos += nr
      _finish if content_length && pos >= content_length
      if (nr = pos - seen) > 0 && mtime <= (Time.now.to_i - frequency)
        self.seen = pos
        self.mtime = Time.now.to_i
      end
    end

    def _finish
      self.content_length ||= self.seen
    end

    def size
      rv = input.size

      # we had an unknown length and just had to read in everything to get it
      if content_length.nil?
        _incr(rv - seen)
        _finish
      end
      rv
    end

    def rewind
      self.pos = 0
      input.rewind
    end

    def gets
      rv = input.gets
      rv.nil? ? _finish : _incr(rv.size)
      rv
    end

    def read(*args)
      rv = input.read(*args)
      rv.nil? || rv.size == 0 ? _finish : _incr(rv.size)
      @logger.info "READ #{pos} bytes (#{rv && rv.size} bytes this time)"
      rv
    end

    def each(&block)
      input.each do |chunk| # usually just a line
        _incr(chunk.size)
        yield chunk
      end
      _finish
    end

    def upload_path?(request_path)
      return true if @paths.nil?

      @paths.any? do |candidate|
        literal_path_match?(request_path, candidate) || wildcard_path_match?(request_path, candidate)
      end
    end

    private

    def file_for(env)
      name, directory = env['HTTP_X_DESTINATION'].split(':')
      filename = env['HTTP_X_FILE_NAME']
      path = File.join(directory, filename)
      targets(env).get(name).file_for(path)
    end

    def write_file(env,file)
      output = file.open 
      sum = Digest::MD5.new
      begin
        loop do
          data = env['rack.input'].read(1048576)
          break if data.nil?
          output.write(data)
          sum.update(data)
        end
        @logger.info "CHECKSUM was: #{sum.hexdigest}"
      ensure
        output.close rescue nil
      end
    end

    def targets(env)
      @targets_class.new(env['HTTP_X_FINDER_KEY']).tap do |targets|
        raise "Invalid user identification provided" unless targets.valid?
      end
    end

    def convert_and_pass_on(env)
      file = file_for(env)
      write_file(env, file)

      fake_file = {
        :filename => env['HTTP_X_FILE_NAME'],
        :type => env['CONTENT_TYPE'],
        :tempfile => file,
      }
      env['rack.request.form_input'] = env['rack.input']
      env['rack.request.form_hash'] ||= {}
      env['rack.request.query_hash'] ||= {}
      env['rack.request.form_hash']['file'] = fake_file
      env['rack.request.query_hash']['file'] = fake_file
      if query_params = env['HTTP_X_QUERY_PARAMS']
        require 'json'
        params = JSON.parse(query_params)
        env['rack.request.form_hash'].merge!(params)
        env['rack.request.query_hash'].merge!(params)
      end
      app.call(env)
    rescue
      STDERR.puts '==== UPLOAD MIDDLEWARE ===='
      STDERR.puts $!.message 
      STDERR.puts $!.backtrace.join("\n")
      STDERR.puts '==========================='
      raise
    end

    def kick_in?(env)
      env['HTTP_X_FILE_UPLOAD'] == 'true' ||
        ! @explicit && env['HTTP_X_FILE_UPLOAD'] != 'false' && raw_file_upload?(env) ||
        env.has_key?('HTTP_X_FILE_UPLOAD') && env['HTTP_X_FILE_UPLOAD'] != 'false' && raw_file_upload?(env)
    end

    def raw_file_upload?(env)
      upload_path?(env['PATH_INFO']) &&
        %{POST PUT}.include?(env['REQUEST_METHOD']) &&
        content_type_of_raw_file?(env['CONTENT_TYPE'])
    end

    def literal_path_match?(request_path, candidate)
      candidate == request_path
    end

    def wildcard_path_match?(request_path, candidate)
      return false unless candidate.include?('*')
      regexp = '^' + candidate.gsub('.', '\.').gsub('*', '[^/]*') + '$'
      !! (Regexp.new(regexp) =~ request_path)
    end
    
    def content_type_of_raw_file?(content_type)
      case content_type
      when %r{^application/x-www-form-urlencoded}, %r{^multipart/form-data}
        false
      else
        true
      end
    end
  end
end
