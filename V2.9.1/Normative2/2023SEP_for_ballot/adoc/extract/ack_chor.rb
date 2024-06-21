module V2AD
  module_function

  def process_ack_chor_table(table, section, opts= {})
    section_num = section.num
    return process_ack_chor_table_5_3_2_x(table, section, opts) if section_num == '5.3.2.4' || section_num == '5.3.2.5' || section_num == '5.3.3.1' || section_num == '5.3.3.2' || section_num == '5.3.3.3' # broken Ack Chor tables....
    if section_num =~ /^5\.9\.\d\.\d/
      if (lines.nil? || lines.empty?)
        return nil
      else
        pp table
      end
    end
    verbose = opts[:verbose] || section_num == '8.14.1'
    puts Rainbow("AckChor").lime if verbose
    ac   = V2AD::AcknowledgementChoreography.new(section)
    
    rows = []
    buffer = ''
    table.rows[1..-2].each_with_index do |row, i|
      
      # Sanity check
      if i == 0
        if row =~ /\|Acknowledge?ment Choreography/
          next
        else
          table.display
          puts table.rows
          raise "Unusual AckChor table"
        end
      end

      if row.strip =~ /or\s+\+$/
        buffer << row.sub(/\+\s*$/, '')
      else
        buffer << row
        rows << buffer.dup
        buffer = ''
      end
    end
    
    rows = rows.map(&:chomp)
    unless rows.size == 6
      puts table.rows
      raise "Unusual AckChor table with #{rows.size} rows."
    end
    
    msg_code = rows.shift.delete('|').strip
    check_msg_code(msg_code, section)
    rows.shift # header
    msh15row   = rows.shift.split('|').map(&:strip)[2..].map { |c| c.split(/,\s*/).sort.join == 'ALERSU' ? 'AL, SU, ER' : c }
    msh16row   = rows.shift.split('|').map(&:strip)[2..].map { |c| c.split(/,\s*/).sort.join == 'ALERSU' ? 'AL, SU, ER' : c }
    immack_row = rows.shift.split('|').map(&:strip)[2..]
    appack_row = rows.shift.split('|').map(&:strip)[2..]
    puts 'for: ' + msg_code if verbose
    # puts msh15row.inspect
    # puts msh16row.inspect
    # puts immack_row.inspect
    # puts appack_row.inspect
    tbl = [msh15row, msh16row, immack_row, appack_row]
    cols = msh15row.zip(msh16row).zip(immack_row).zip(appack_row).map(&:flatten)
    
    nene = cols.find { |c| c[0] == 'NE' && c[1] == 'NE' }
    neal = cols.find { |c| c[0] == 'NE' && c[1] == 'AL, SU, ER' }
    alne = cols.find { |c| c[0] == 'AL, SU, ER' && c[1] == 'NE' }
    alal = cols.find { |c| c[0] == 'AL, SU, ER' && c[1] == 'AL, SU, ER' }
    
    originalacks = nil
    msh15acks = nil
    msh16acks = nil
    
    col1 = cols.first
    
    raise "Col1 is weird in section #{section_num}: #{col1}" unless col1[0] == 'Blank' && col1[1] == 'Blank'
    
    im_ack_in_orig  = (col1[2] != '-' && col1[2].size > 1) ? col1[2] : false
    app_ack_in_orig = (col1[3] != '-' && col1[3].size > 1) ? col1[3] : false
    raise "Can't be both in original mode for section #{section_num}: #{col1}" if im_ack_in_orig && app_ack_in_orig
    
    # TODO if there is an original mode ack, ac.original_acks
    orig_ack_str = im_ack_in_orig || app_ack_in_orig
    if orig_ack_str
      ac.ack_immediate = !!im_ack_in_orig
      ac.original_acks = get_message_codes(orig_ack_str)
      ac.original_acks.each { |code| check_msg_code(code, section) }
    end
    
    if nene
      raise 'nene ' + section_num if nene[2] != '-'
      raise 'nene ' + section_num if nene[3] != '-'
    end
    
    v15 = msh15row[1..-1].uniq
    if v15.size == 1
      raise "v15 for section #{section_num}: #{v15}"  unless section_num == '14.3.2'
      ac.msh15 = v15.first
    end
    v16 = msh16row[1..-1].uniq
    if v16.size == 1
      raise "v16 for section #{section_num}: #{v16}" unless v16.first == 'NE' || v16.first == 'AL' ||  section_num == '14.3.2'
      ac.msh16 = v16.first
    end
    
    oddv = (v15 + v16) - ['NE', 'AL, SU, ER', 'AL']
    if oddv.any?
      raise "oddv for section #{section_num}: #{oddv}" unless section_num == '14.3.2'
    end
    
    if neal
      raise 'neal2 ' + section_num if neal[2] != '-'
    end
    
    if alne
      raise 'alne3 ' + section_num if alne[3] != '-' unless section_num == '4.6.2' # FIXME ensure that 4.6.2 get's fixed in the source or downstream of here
    end

    if alne && alal
      raise 'alne2 != alal2' unless alne[2] == alal[2]
    end
    
    if alne || alal
      ac.msh15_acks = get_message_codes(alal&.[](2) || alne&.[](2))
      ac.msh15_acks.each { |code| check_msg_code(code, section) }
    end
    
    if neal && alal
      raise 'neal3 != alal3 in section ' + section_num unless neal[3] == alal[3] unless section_num == '14.3.2' || section_num == '16.3.12'
      puts Rainbow('Fix Ack Chor for 14.3.2!').red if section_num == '14.3.2'
    end
    
    if neal || alal
      ac.msh16_acks = get_message_codes(alal&.[](3) || neal&.[](3))
      ac.msh16_acks.each { |code| check_msg_code(code, section) }
    end
    if verbose
      puts "neal #{neal}"
      puts "alal #{alal}"
      puts "#{alal&.[](3) || neal&.[](3)}"
      puts "Original Acks: #{ac.original_acks}"
      puts "MSH15 Acks:    #{ac.msh15_acks}"
      puts "MSH16 Acks:    #{ac.msh16_acks}"
    end    
    
      
    # TODO 
    # check that NE always corresponds to no message and AL always corresponds to a message
    msh15row[1..-1].each_with_index do |c, i|
      if c =~ /NE/
        raise 'Weird msg NE values in MSH15 row in section ' + section_num if immack_row[i+1] != '-'
      elsif c =~ /AL/
        immack = immack_row[i+1]
        # puts "#{c} --> #{immack}"
        # puts immack =~ /[A-Z0-9]{3}\^/
        raise "Weird msg AL values in MSH15[#{i+1}] row in section #{section_num}\n#{msh15row}\n#{immack_row}" unless immack =~ /[A-Z0-9]{3}\^/
      else
        raise 'Weird values in MSH15 row in section ' + section_num
      end
    end
    msh16row[1..-1].each_with_index do |c, i|
      if c =~ /NE/
        raise 'Weird msg NE values in MSH16 row in section ' + section_num if appack_row[i+1] != '-' unless section_num == '4.6.2'
      elsif c =~ /AL/
        appack = appack_row[i+1]
        # puts "#{c} --> #{appack}"
        # puts appack =~ /[A-Z0-9]{3}\^/
        
        raise "Weird msg AL values in MSH16[#{i+1}] row in section #{section_num}\n#{msh16row}\n#{appack_row}" unless appack =~ /[A-Z0-9]{3}\^/ || section_num =~ /^5\.4\.(1|2|3|4|5|6)$/ ||  section_num == '8.14.1'
      else
        raise 'Weird values in MSH16 row in section ' + section_num
      end
    end
    table.objects << ac
    ac
  end
  
  def process_ack_chor_table_5_3_2_x(table, section, opts)
    section_num = section.num
    verbose = opts[:verbose]
    puts Rainbow("AckChor").lime if verbose
    ac = V2AD::AcknowledgementChoreography.new(section)
    return ac # FIXME the spec is broken so I really don't know what to do here without some guidance.  
    rows = []
    buffer = ''
    table.rows.each do |l|
      if l.strip =~ /or\s+\+$/
        buffer << l.sub(/\+\s*$/, '')
      else
        buffer << l
        rows << buffer.dup
        buffer = ''
      end
    end
    rows = rows.map(&:chomp)
    msg = rows.shift.delete('|').strip
    check_msg_code(msg, section)
    rows.shift # header
    msh15row   = rows.shift.split('|').map(&:strip)[2..].map { |c| c.split(/,\s*/).sort.join == 'ALERSU' ? 'AL, SU, ER' : c }
    msh16row   = rows.shift.split('|').map(&:strip)[2..].map { |c| c.split(/,\s*/).sort.join == 'ALERSU' ? 'AL, SU, ER' : c }
    immack_row = rows.shift.split('|').map(&:strip)[2..]
    puts 'for: ' + msg if verbose
    # puts msh15row.inspect
    # puts msh16row.inspect
    # puts immack_row.inspect
    # puts appack_row.inspect
    tbl = [msh15row, msh16row, immack_row]
    cols = msh15row.zip(msh16row).zip(immack_row).map(&:flatten)
    
    nene = cols.find { |c| c[0] == 'NE' && c[1] == 'NE' }
    neal = cols.find { |c| c[0] == 'NE' && c[1] == 'AL, SU, ER' }
    alne = cols.find { |c| c[0] == 'AL, SU, ER' && c[1] == 'NE' }
    alal = cols.find { |c| c[0] == 'AL, SU, ER' && c[1] == 'AL, SU, ER' }
    
    originalacks = nil
    msh15acks    = nil
    msh16acks    = nil
    
    col1 = cols.first
    
    raise "Col1 is weird in section #{section_num}: #{col1}" unless col1[0] == 'Blank' && col1[1] == 'Blank'
    
    im_ack_in_orig  = false
    app_ack_in_orig = false
    raise "Can't be both in original mode for section #{section_num}: #{col1}" if im_ack_in_orig && app_ack_in_orig
    
    # TODO if there is an original mode ack, ac.original_acks
    orig_ack_str = im_ack_in_orig || app_ack_in_orig
        
    v15 = msh15row[1..-1].uniq
    if v15.size == 1
      raise "v15 for section #{section_num}: #{v15}"  unless section_num == '14.3.2'
      ac.msh15 = v15.first
    end
    
    if alne || alal
      ac.msh15_acks = get_message_codes(alal&.[](2) || alne&.[](2))
      ac.msh15_acks.each { |code| check_msg_code(code, section) }
    end
    
    if neal && alal
      raise 'neal3 != alal3 in section ' + section_num unless neal[3] == alal[3] unless section_num == '14.3.2' || section_num == '16.3.12'
      puts Rainbow('Fix Ack Chor for 14.3.2!').red if section_num == '14.3.2'
    end
    
    if neal || alal
      ac.msh16_acks = get_message_codes(alal&.[](3) || neal&.[](3))
      ac.msh16_acks.each { |code| check_msg_code(code, section) }
    end
      
    # puts "Original Acks: #{ac.original_acks}"
    # puts "MSH15 Acks:    #{ac.msh15_acks}"
    # puts "MSH16 Acks:    #{ac.msh16_acks}"
    
    
      
    # TODO 
    # check that NE always corresponds to no message and AL always corresponds to a message
    msh15row[1..-1].each_with_index do |c, i|
      if c =~ /NE/
        raise 'Weird msg NE values in MSH15 row in section ' + section_num if immack_row[i+1] != '-'
      elsif c =~ /AL/
        immack = immack_row[i+1]
        # puts "#{c} --> #{immack}"
        # puts immack =~ /[A-Z0-9]{3}\^/
        raise "Weird msg AL values in MSH15[#{i+1}] row in section #{section_num}\n#{msh15row}\n#{immack_row}" unless immack =~ /[A-Z0-9]{3}\^/
      else
        raise 'Weird values in MSH15 row in section ' + section_num
      end
    end
    msh16row[1..-1].each_with_index do |c, i|
      if c =~ /NE/
        raise 'Weird msg NE values in MSH16 row in section ' + section_num if appack_row[i+1] != '-'
      elsif c =~ /AL/
        appack = appack_row[i+1]
        # puts "#{c} --> #{appack}"
        # puts appack =~ /[A-Z0-9]{3}\^/
        
        raise "Weird msg AL values in MSH16[#{i+1}] row in section #{section_num}\n#{msh16row}\n#{appack_row}" unless appack =~ /[A-Z0-9]{3}\^/ || section_num =~ /^5\.4\.(1|2|3|4|5|6)$/
      else
        raise 'Weird values in MSH16 row in section ' + section_num
      end
    end

    ac
  end
  
  def check_msg_code(code, section)
    section_num = section.num
    return if ['3.3.37', '10.3'].include?(section_num)
    mt, ec, ms = code.split('^')
    if mt == 'ACK' || ms == 'ACK'
      raise "Bad code: #{code} from section #{section_num}" unless mt == ms
    end
  end
  
  def ack_conditions(str)
    if msh15row == 'NE'
      'NE'
    elsif msh15row.split(/\s+,/).sort.join == 'ALERSU'
      'AL, SU, ER'
    else
      str = 'ERROR: ' + str
      puts str 
      str
    end
  end
end
