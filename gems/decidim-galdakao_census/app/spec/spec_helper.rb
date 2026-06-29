# frozen_string_literal: true

require "spec_helper"
require "simplecov"
SimpleCov.start "rails"
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "decidim/dev"

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "../.."))

require "decidim/dev/test/base_spec_helper"
EOF