class RubimaLint
   NOT_ASCII  = '[^[:ascii:]]'     # 非ASCII
   ASCII_CHAR = '[\w&&[:ascii:]]'  # ASCII
   OPEN_PARENTHESES  = '[(]'  # 開き丸括弧
   CLOSE_PARENTHESES = '[)]'  # 閉じ丸括弧
   QUESTION_EXCLAMATION = '[？！]'  # 疑問符・感嘆符
   PUNCTUATION = "[、。#{QUESTION_EXCLAMATION}]"  # 句読点
   OPEN_BRANCKETS  = '[「『]'  # 開き括弧類
   CLOSE_BRANCKETS = '[』」]'  # 閉じ括弧類
   THREE_POINT_LEADER = '[…]'  # 三点リーダ
   OTHER_OK_LETTER = "[#{THREE_POINT_LEADER}〜：　]"  # その他OK文字
   OK_BEFORE_ASCII = "[#{PUNCTUATION}#{OPEN_BRANCKETS}#{OTHER_OK_LETTER}]"  # ASCII直前のOK文字
   OK_AFTER_ASCII = "[#{PUNCTUATION}#{CLOSE_BRANCKETS}#{OTHER_OK_LETTER}]"  # ASCII直後のOK文字
   HEAD_CHAR = "'''　"  # 発言頭
   ASCII_AFTER_NOT_ASCII = /(?<=#{NOT_ASCII})(?=#{ASCII_CHAR})(?<!#{OK_BEFORE_ASCII})(?<!#{HEAD_CHAR})/o  # 非ASCIIの直後にASCII
   NOT_ASCII_AFTER_ASCII = /(?<=#{ASCII_CHAR})(?=#{NOT_ASCII})(?!#{OK_AFTER_ASCII})/o  # ASCIIの直後に非ASCII
   MISSING_BLANK = /#{ASCII_AFTER_NOT_ASCII}|#{NOT_ASCII_AFTER_ASCII}/o  # 空白抜け

   # 円括弧前後OK文字
   OK_AROUND_PARENTHESES = "[ [[:ascii:]&&[:graph:]]#{PUNCTUATION}#{OPEN_BRANCKETS}#{CLOSE_BRANCKETS}#{THREE_POINT_LEADER}]"

   union = [
      /(?<!^)(?<!#{HEAD_CHAR})(?<!#{OK_AROUND_PARENTHESES})#{OPEN_PARENTHESES}/o,
      /#{CLOSE_PARENTHESES}(?!#{OK_AROUND_PARENTHESES})(?!$)/o,
      PARENTHESES_AT_END_OF_STATE = /。#{CLOSE_PARENTHESES}。/o,  # 文末で括弧を閉じる場合
         LAUGH_AND_PARENTHESES = /笑#{CLOSE_PARENTHESES}。$/o,    # 括弧笑の後の句点
         SINGLE_THREE_POINT_LEADER = /(?<!#{THREE_POINT_LEADER})#{THREE_POINT_LEADER}(?!#{THREE_POINT_LEADER})/o,  # 単独の三点リーダ
         THREE_POINT_LEADER_AT_END = /#{THREE_POINT_LEADER}$/o,  # 文末の三点リーダ
      QUESTION_EXCLAMATION_IN_PARAGRAPH = /#{QUESTION_EXCLAMATION}(?!$)(?![　#{QUESTION_EXCLAMATION}#{CLOSE_BRANCKETS}])/o,  # 段落中の疑問符・感嘆符
      FULL_WIDTH_PARENTHESES = /[（）]/o,  # 全角括弧
   ]
   INVALID_PATTERN = Regexp.union(*union)

   CHAR_AROUND_NOT_PERMIT_BLANK = "[#{PUNCTUATION}#{OPEN_BRANCKETS}#{CLOSE_BRANCKETS}]"
   union = [
      /#{THREE_POINT_LEADER} #{OPEN_PARENTHESES}/o,
      /#{CHAR_AROUND_NOT_PERMIT_BLANK} #{OPEN_PARENTHESES}/o,
      /#{CLOSE_PARENTHESES} #{CHAR_AROUND_NOT_PERMIT_BLANK}/o,
   ]
   INVALID_BLANK = Regexp.union(*union)

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
      line.gsub!(MISSING_BLANK) do
         check_result = true
         @warning_count += 1
         "\e[7m \e[m"
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def invalid_pattern_check(lineno, line)
      check_result = false
      line.gsub!(INVALID_PATTERN) do
         check_result = true
         @warning_count += 1
         "\e[31m#{$&}\e[m"
      end
      add_msg("#{lineno} : #{line}") if check_result
   end

   def unnecessary_space_check(lineno, line)
      check_result = false
      line.gsub!(INVALID_BLANK) do
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

