# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 98.41
  add_filter '/spec/'
  add_filter '/vendor/bundle/'
end
