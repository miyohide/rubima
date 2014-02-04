require 'minitest/spec'
require 'minitest/autorun'
require 'open3'

describe "Rubima-Lint" do

   describe "アスキー文字の前後にスペース" do
      describe "アスキー文字の前にスペースがないとき" do
         it "警告が出ること" do
            Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
               stdin.puts "アスキー文字の前にスペースabc が必要です"
               stdin.close
               stdout.read.must_match /1 warning/m
            }
         end
      end

      describe "アスキー文字の後にスペースがないとき" do
         it "警告が出ること" do
            Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
               stdin.puts "アスキー文字の前にスペース abcが必要です"
               stdin.close
               stdout.read.must_match /1 warning/m
            }
         end
      end

      describe "アスキー文字の前後にスペースがないとき" do
         it "2つ警告が出ること" do
            Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
               stdin.puts "アスキー文字の前後にスペースabcが必要です"
               stdin.close
               stdout.read.must_match /2 warning/m
            }
         end
      end
   end

   describe "invalid pattern" do
      describe "三点リーダ" do
         describe "単独で使っている時" do
            it "警告が出ること" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "単独の三点リーダ…です。"
                  stdin.close
                  stdout.read.must_match /1 warning/m
               }
            end
         end

         describe "2文字で使っている時" do
            it "警告が出ないこと" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "二文字の三点リーダ……です。"
                  stdin.close
                  stdout.read.must_equal ""
               }
            end
         end

         describe "文末で使い句点がない時" do
            it "警告が出ること" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "二文字の三点リーダ……"
                  stdin.close
                  stdout.read.must_match /1 warning/m
               }
            end
         end

         describe "文末で使い句点がある時" do
            it "警告が出ないこと" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "二文字の三点リーダ……。"
                  stdin.close
                  stdout.read.must_equal ""
               }
            end
         end
      end

   end

   describe "TODO" do
      it "文中にあれば警告が出ること" do
         Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
            stdin.puts "備忘録を表す TODO がある場合は警告を出す。"
            stdin.close
            stdout.read.must_match /1 warning/m
         }
      end
   end

end
