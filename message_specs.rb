# Copyright Vidaguard 2013
# Author: Claudio Mendoza
require 'yaml'

class MessageSpecs
  def self.initialize
    desc = YAML.load_file('msg_specs.yml')
    desc.each do |typ, vals|
      set_vals(typ, vals)
    end
    desc
  end

  def self.set_vals(typ, vals)
    vals.each do |seq, val|
      begin
        if val.kind_of?(String)
          arr = val.gsub(' ','').split(',')
          vals[seq] = arr
        else
          set_vals(typ, val)
        end
      rescue
        puts "Error in typ #{typ} desc #{seq} def #{str}"
      end
    end
    vals
  end

  class FieldSpec
    attr_accessor :name, :req, :length, :const
  end
end