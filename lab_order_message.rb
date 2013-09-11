require 'hl7_message'
class LabOrderMessage < HL7Message
  # Copyright Vidaguard 2013
  # Author: Claudio Mendoza

  SEGS=[:MSH, :PID, :NTE, :ZCP, :PD1, :PV1, :PV2, :GT1, :IN1, :IN2, :ORC, :ZCF, :OBR, :NTE, :DG1, :OBX, :NTE]

  def initialize(hsh)
    super

  end
end