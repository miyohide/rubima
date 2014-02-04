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

      describe "文末で括弧を閉じる" do
         describe "句点 + 閉じ括弧 + 句点となっている場合" do
            it "警告が出ること" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "本文 (追加の文。)。"
                  stdin.close
                  stdout.read.must_match /1 warning/m
               }
            end
         end

         describe "句点以外 + 閉じ括弧 + 句点となっている場合" do
            it "警告が出ないこと" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "本文 (追加の文)。"
                  stdin.close
                  stdout.read.must_equal ""
               }
            end
         end

         describe "句点 + 閉じ括弧となっている場合" do
            it "警告が出ないこと" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "本文。(追加の文。) です。"
                  stdin.close
                  stdout.read.must_equal ""
               }
            end
         end
      end

      describe "括弧笑の後の句点" do
         describe "顔文字やそれに準じるものの後に句点があるとき" do
            it "警告が出ること" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "笑)。"
                  stdin.close
                  stdout.read.must_match /1 warning/m
               }
            end
         end

         describe "顔文字やそれに準じるものの後に句点がないとき" do
            it "警告が出ないこと" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "笑)"
                  stdin.close
                  stdout.read.must_equal ""
               }
            end
         end
      end

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

      describe "段落中の疑問符・感嘆符" do
         describe "疑問符・感嘆符の次に全角スペースがないとき" do
            it "警告が出ること" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  # 半角スペースを含めている
                  stdin.puts "疑問符？ 感嘆符"
                  stdin.close
                  stdout.read.must_match /1 warning/m
               }
            end
         end

         describe "疑問符・感嘆符の次に全角スペースがあるとき" do
            it "警告が出ないこと" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "感嘆符！　疑問符"
                  stdin.close
                  stdout.read.must_equal ""
               }
            end
         end
      end

      describe "全角括弧" do
         it "開き全角括弧が使われているときは警告が出ること" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "全角（括弧テスト。"
                  stdin.close
                  stdout.read.must_match /1 warning/m
               }
         end

         it "閉じ全角括弧が使われているときは警告が出ること" do
               Open3.popen3("ruby rubima-lint.rb") { |stdin, stdout, stderr|
                  stdin.puts "全角括弧）テスト。"
                  stdin.close
                  stdout.read.must_match /1 warning/m
               }

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
