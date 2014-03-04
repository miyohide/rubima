require 'minitest/spec'
require 'minitest/autorun'
require File.expand_path('../../rubima-lint', __FILE__)

describe RubimaLint do
   describe "[[名前|https://foo.bar]]形式のとき" do
      before do
         @line = "[[名前|https://foo.bar]]"
      end
      it "引数と戻り値が一緒であること" do
         RubimaLint.new.link_check(@line).must_equal @line
      end
   end

end

