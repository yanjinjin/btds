#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

require "#{Rails.root}/app/models/rule.rb"

Rule.input(ARGV)
