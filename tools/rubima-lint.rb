class RubimaLint
   Const非ascii = '[^[:ascii:]]'
   Constascii = '[\w&&[:ascii:]]'
   Const開き丸括弧 = '[(]'
   Const閉じ丸括弧 = '[)]'
   Const疑問符・感嘆符 = '[？！]'
   Const句読点 = "[、。#{Const疑問符・感嘆符}]"
   Const開き括弧類 = '[「『]'
   Const閉じ括弧類 = '[』」]'
   Const三点リーダ = '[…]'
   Constその他ok文字 = "[#{Const三点リーダ}〜：　]"
   Constasciiの直前ok文字 = "[#{Const句読点}#{Const開き括弧類}#{Constその他ok文字}]"
   Constasciiの直後ok文字 = "[#{Const句読点}#{Const閉じ括弧類}#{Constその他ok文字}]"
   Const発言頭 = "'''　"
   Const非asciiの直後にascii = /(?<=#{Const非ascii})(?=#{Constascii})(?<!#{Constasciiの直前ok文字})(?<!#{Const発言頭})/o
   Constasciiの直後に非ascii = /(?<=#{Constascii})(?=#{Const非ascii})(?!#{Constasciiの直後ok文字})/o
   Const空白抜け = /#{Const非asciiの直後にascii}|#{Constasciiの直後に非ascii}/o

   Const丸括弧前後ok文字 = "[ [[:ascii:]&&[:graph:]]#{Const句読点}#{Const開き括弧類}#{Const閉じ括弧類}#{Const三点リーダ}]"

   union = [
      /(?<!^)(?<!#{Const発言頭})(?<!#{Const丸括弧前後ok文字})#{Const開き丸括弧}/o,
      /#{Const閉じ丸括弧}(?!#{Const丸括弧前後ok文字})(?!$)/o,
      Const文末で括弧を閉じる場合 = /。#{Const閉じ丸括弧}。/o,
         Const括弧笑の後の句点 = /笑#{Const閉じ丸括弧}。$/o,
         Const単独の三点リーダ = /(?<!#{Const三点リーダ})#{Const三点リーダ}(?!#{Const三点リーダ})/o,
         Const文末の三点リーダ = /#{Const三点リーダ}$/o,
      Const段落中の疑問符・感嘆符 = /#{Const疑問符・感嘆符}(?!$)(?![　#{Const疑問符・感嘆符}#{Const閉じ括弧類}])/o,
      Const全角括弧 = /[（）]/o,
   ]
   Constinvalid_pattern = Regexp.union(*union)

   Const括弧の前後にあると空白を入れない文字 = "[#{Const句読点}#{Const開き括弧類}#{Const閉じ括弧類}]"
   union = [
      /#{Const三点リーダ} #{Const開き丸括弧}/o,
      /#{Const括弧の前後にあると空白を入れない文字} #{Const開き丸括弧}/o,
      /#{Const閉じ丸括弧} #{Const括弧の前後にあると空白を入れない文字}/o,
   ]
   Const不要な空白 = Regexp.union(*union)

   attr_reader :warning_count, :error_messages

   def initialize
      @warning_count = 0
      @error_messages = []
      @fn = false
      @last_hrule = false
   end

   def add_msg(msg)
      @error_messages << msg
      msg
   end

   def white_space_check(lineno, line)
      check_result = false
      line.gsub!(Const空白抜け) do
         check_result = true
         @warning_count += 1
         "\e[7m \e[m"
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def invalid_pattern_check(lineno, line)
      check_result = false
      line.gsub!(Constinvalid_pattern) do
         check_result = true
         @warning_count += 1
         "\e[31m#{$&}\e[m"
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def unnecessary_space_check(lineno, line)
      check_result = false
      line.gsub!(Const不要な空白) do
         check_result = true
         @warning_count += 1
         "\e[32m#{$&}\e[m"
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def todo_check(lineno, line)
      check_result = false
      line.gsub!(/TODO/) do
         check_result = true
         @warning_count += 1
         "\e[33m#{$&}\e[m"
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def link_check(lineno, line)
      check_result = false
      line.gsub!(/(?<left>\[\[(.*?\|)?)(?<link>.*)(?<right>\]\])/) do
         m = $~
         if m[:link] !~ %r!\Ahttps?://! &&  m[:link] =~ /[^0-9A-Za-z\-_]/
            check_result = true
            @warning_count += 1
            "#{m[:left]}\e[34m#{m[:link]}\e[m#{m[:right]}"
         end
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def toc_check(lineno, line)
      check_result = false
      line.gsub!(/\{\{toc\}\}/) do
         @warning_count += 1
         "\e[35m#{$&}\e[m"
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def footnote_check(lineno, line)
      @fn = true if /\{\{fn/ =~ line
   end

   def last_hrule_check(lineno, line)
      if /^----$/ =~ line
         @last_hrule = true
      elsif /\S/ =~ line
         @last_hrule = false
      end
   end

   def footnote_pair_check
      if @fn && !@last_hrule
         @warning_count += 1
         puts "\e[7m脚注があるのに末尾に「----」がない。\e[m"
      elsif !@fn && @last_hrule
         @warning_count += 1
         puts "\e[7m脚注がないのに末尾に「----」がある。\e[m"
      end
   end

end

if $0 == __FILE__
   checker = RubimaLint.new
   ARGF.each do |line|

      checker.white_space_check(ARGF.lineno, line)
      checker.invalid_pattern_check(ARGF.lineno, line)
      checker.unnecessary_space_check(ARGF.lineno, line)
      checker.todo_check(ARGF.lineno, line)
      checker.link_check(ARGF.lineno, line)
      checker.toc_check(ARGF.lineno, line)

      checker.footnote_check(ARGF.lineno, line)
      checker.last_hrule_check(ARGF.lineno, line)
   end

   checker.footnote_pair_check

   checker.error_messages.each do |error_message|
      puts error_message
   end

   if checker.warning_count > 0
      puts "#{checker.warning_count} warning(s)"
      exit(false)
   end
end

