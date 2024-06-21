module V2AD
  module_function
  
  # This is just a check to make sure the event already exists....I think....
  def extract_event_ch10(section, opts = {})
    section_num = section.num
    l1 = section.title
    code = l1.slice(/(?<=\(Event).+(?=\))/)&.strip
    name = l1.slice(/.+(?=\(Event)/).strip.sub(/^\d*\s*/, '')
    unless code && name
      section.display
      puts l1
      raise
    end
    # puts Rainbow(section).coral + " #{name} (Event #{code})"
    # event = V2AD::Event.new(code, name, section)
    event = V2AD.v2.events[code].find { |e| e.section == section }
    raise 'No event' unless event
  end
  
end
