#==============================================================================
# Copyright (C) 2007-2011 Stephen F Norledge & Alces Software Ltd.
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
require 'rubygems'

begin
  require 'bundler'
rescue LoadError
  $stderr.puts "You must install bundler - run `gem install bundler`"
end

begin
  Bundler.setup
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'bueller'
Bueller::Tasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:examples) do |examples|
  examples.rspec_opts = '-Ispec'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.rspec_opts = '-Ispec'
  spec.rcov = true
end

task :default => :examples

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.main = 'README.rdoc'
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "alces-upload-middleware #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
