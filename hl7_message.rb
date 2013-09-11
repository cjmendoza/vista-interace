require 'ruby-hl7'

class HL7Message < HL7::Message
  # Copyright Vidaguard 2013
  # Author: Claudio Mendoza

  def initialize(specs, vals = nil)
    super nil
    @specs = specs
    msh = HL7::Message::Segment::MSH.new
    set_values(msh, vals)
    self << msh
  end

  def add_segment(typ, values, idx = nil)
    seg = create_segment(typ.to_s, values)
    self << seg unless idx
    self[idx] = seg if idx
  end

  def create_segment(typ, values)
    class_name = "HL7::Message::Segment::#{typ}"
    klass = class_name.split('::').inject(Object) { |o, c| o.const_get c }
    klass.new
    seg = klass.new
    set_values(seg, values)
  end

  def set_values(seg, vals)
    vals.each do |key, val|
      add_val = val.kind_of?(Hash) ? set_field_values(seg, key, vals) : val
      seg.send(key, add_val)
    end
    seg
  end

  def set_field_values(seg, fld, vals)
    val = ""
    @lev = @lev ? @lev+=1 : 1
    delim = @lev == 1 ? self[:MSH].enc_chars[0, 1] : self[:MSH].enc_chars[3, 1]
    odel = ''
    fld_desc = @specs[segment_type(seg)][fld.to_s]
    (1..fld_desc.length).each do |idx|
      desc = fld_desc[idx]
      if desc[0] == 'f'
        add_val = set_field_values(seg, desc[1], vals[fld])
      else
        add_val = "#{odel}#{vals[fld.to_sym][desc[1].to_sym]}"
      end
      val += add_val
      odel = delim
    end
    @lev -= 1
    val
  end

  def segment_type(seg)
    seg.class.to_s.split('::').last
  end

  def self.parse(str)
    HL7::Message.new str
  end


end