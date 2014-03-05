# encoding: utf-8

begin
  require 'bundler/gem_helper'

  namespace 'gem' do
    Bundler::GemHelper.install_tasks
  end

rescue LoadError
end
