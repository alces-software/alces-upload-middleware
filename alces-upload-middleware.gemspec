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
$:.push File.expand_path("../lib", __FILE__)
require 'alces-upload-middleware/version'

Gem::Specification.new do |s|
  s.name = 'alces-upload-middleware'
  s.version = AlcesUploadMiddleware::VERSION
  s.platform = Gem::Platform::RUBY
  s.date = "2013-01-14"
  s.authors = ['Mark J. Titorenko']
  s.email = 'mark.titorenko@alces-software.com'
  s.homepage = 'http://github.com/alces-software/alces-upload-middleware'
  s.summary = %Q{Alces Software upload middleware for Rack}
  s.description = %Q{Rack middleware that streams plain file uploads to configurable destinations before converting into normal form input to allow Rack applications to read them using standard file upload semantics.}
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.rdoc',
  ]

  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.7')
  s.rubygems_version = '1.3.7'
  s.specification_version = 3

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'json'
  s.add_development_dependency 'geminabox'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'bueller', '0.0.9'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'simplecov'
end

