module V2AD

  class Message < V2Obj
    attr_accessor :message_type, :message_structure, :response_to, :ack_to, :trigger, :ack_chor
    attr_reader :responses, :ack, :call_stack
    
    def in_excluded_calls(call)
      !!(call =~ /event.rb:14|events.rb:247/)
    end
    
    def in_known_calls(call)
      !!(call =~ /ack_helpers.rb/)
    end
      
    
    def initialize(section = nil)
      raise unless section
      @section       = section
      @responses     = []
      @response_to   = []
      @ack_to        = []
      @call_stack = caller.map { |l| l }
      V2AD.v2.messages << self
      V2AD.register_to_section(section, self) if section
      unless true && %q{1 2 4 5 6 7 8 9}.include?(section.num[0])
        # puts section.num
        @call_stack.each do |l|
          if in_excluded_calls(l)
            # puts Rainbow(l).magenta
            break
          end
          if in_known_calls(l)
            # puts Rainbow(l).coral
            next
          end
          # puts Rainbow(l).cornflower
          break
        end
      end
    end
    
    def sequel=(obj)
      @sequel = obj
      # puts caller
      # raise "Someone set this"
    end
      
        
    def add_response(resp_msg)
      @responses << resp_msg
      resp_msg.section ||= @section
      resp_msg.response_to << self
    end

    def ack=(ack_msg)
      # if section.num == '3.3.56'
      #   puts caller
      #   raise
      # end
      @ack = ack_msg
      ack_msg.section ||= @section
      unless ack_msg.is_a?(Message)
        puts ack_msg.class.name
        raise
      end
      ack_msg.ack_to << self
    end
    
    def section
      return @section if @section
      return trigger.section if trigger
      return response_to.first.section if response_to.any?
      return ack_to.first.section if ack_to.any?
      return nil
    end
    
    def withdrawn?
      ev = (trigger || response_to.first&.trigger || ack_to.first&.trigger || ack_to.first.response_to.first&.trigger)
      # pp trigger&.code
      # pp response_to.map(&:code)
      # pp ack_to.map(&:code)
      # pp ack_to.first.trigger&.code
      raise "No event for message #{code} from section #{section.num}" unless ev
      ev.status.to_s == 'W' || ev.status.to_s =~ /withdrawn/i
    end
        
    def structure
      message_structure
    end
    
    def event_code
      ec = trigger&.code
      return ec if ec
      raise "Now what?" if response_to.size > 1
      ec = response_to&.first&.trigger&.code || ack_to&.first&.trigger&.code || ack_to&.first&.response_to&.first&.trigger&.code
      unless ec
        section.display
        puts message_type.code
        puts "Response to: #{response_to&.first&.event_code}"
        # response_to.each { |msg| puts m.message_type.code }
        puts "Ack to: #{ack_to&.first&.event_code}"
        ack_to.each do |msg|
          puts msg.section.num
          begin
            puts self
            puts msg.message_type.code
            puts msg.trigger&.code
          rescue
            puts self.section.num
            raise
          end
          puts msg.responses.size
          puts !!msg.ack
        end
        raise 'AC for nothing?'
      end
      ec
    end
    
    def code(strict = true)
      ec  = event_code
      mtc = message_type&.code
      sc  = structure&.code
      ret = "#{mtc || '***'}^#{ec || '***'}^#{sc || '***'}"
      if !(ec && mtc && sc) && !(trigger&.status == 'W')
        unless ['E30', 'E31'].include?(ec)
          puts Rainbow("Message #{ret} with malformed code from section: #{section.num}").orange
          if strict
            puts self.call_stack; raise
            puts "Event code: " + ec
            puts "Message type: " + (mtc || 'NONE')
            puts "Structure: " + (sc || 'NONE')
            puts section.num
            if ack_to.any?
              puts "Ack to: #{ack_to.map(&:code)}"
            end
            if response_to.any?
              puts "Response to: #{ack_to.map(&:code)}"
            end
            if trigger
              puts "Direct Trigger: #{trigger.code}"
            end
            puts "Self: #{self.object_id}"
            events = V2.instance.events[ec]
            events.each do |event|
              puts "Event #{event.code}"
              msg = event.message
              puts "Msg: #{msg.code}"
              resps = msg.responses
              if resps.any?
                resps.each do |resp|
                  puts "Response: #{resp.code}"
                  rack = resp.ack
                  if rack
                    rec = rack.message_structure&.code || 'FIXME'  
                    puts "Reponse ack: #{rack.message_type.code}^#{rack.event_code}^#{rec}"
                  end
                end
              end
              msgack = msg.ack
              if msgack
                puts msgack.section
              end
            end
            raise
          end
        end
      end
      ret
    end
    
    def message_structure=(ms)
      @message_structure = ms
      ms.messages << self
    end
    
    def message_type=(mt)
      @message_type = mt
      if section.num == '3.3.56'
        # puts caller
        # puts Rainbow("Kingo mt == #{mt.code}").green
      end
      mt.messages << self
    end
    
    def ack_chor=(ac)
      @ack_chor = ac
      ac.for << self
    end
    
=begin
    def ack_to_code
      if ack_to.size == 1
        af = ack_to.first
        af.trigger&.code || af.response_to_code
      else
        codes = ack_to.map { |af| af.trigger&.code || af.response_to_code }
        codes = codes.flatten.uniq
        if codes.size == 1
          codes.first
        elsif codes.size > 1
          raise "Multiple event codes for ACK message: #{codes}"
        else
          puts !!self.trigger
          puts self.response_to.size
          puts self.ack_to.size
          puts self.structure.code
          raise "No event associated with ACK message"
        end
      end
    end
    
    def response_to_code
      if response_to.size == 1
        response_to.first.trigger.code
      else
        codes = response_to.map { |rf| codes << rf.trigger.code }
        codes.uniq!
        if codes.size == 1
          codes.first
        else
          raise "Multiple event codes for response message: #{codes}"
        end
      end
    end
=end
  end
  
  module_function
  
  def get_messages(message_codes)
    message_codes.map { |c| get_message(c) } 
  end

  def get_message(code)
    mt, ec, ms = code.split('^')
    event = V2.instance.events[ec]
    msg   = event.message
    msg
  end

end
