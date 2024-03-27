# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 95.17, branch: 85.13
  add_filter '/spec/'
  add_filter '/vendor/bundle/'
end
