require 'minitest/spec'
require 'minitest/autorun'
require File.expand_path('../../rubima-lint', __FILE__)

describe RubimaLint do

   describe "TODO" do
      before do
         @line = "TODO これをやる"
      end

      it { RubimaLint.new.todo_check(1, @line).must_equal "" }
   end
   
   describe "TODO2" do
      before do
         @line = "これをやる"
      end

      it { RubimaLint.new.todo_check(1, @line).must_equal "" }
   end
end

