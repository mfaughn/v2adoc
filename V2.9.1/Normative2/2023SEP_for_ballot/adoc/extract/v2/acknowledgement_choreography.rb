module V2AD

  class AcknowledgementChoreography
    attr_accessor :ack_immediate, :original_acks, :msh15_acks, :msh16_acks, :imm_ack, :app_ack, :notes, :for, :msh15, :msh16, :sequel, :section
    def initialize(section)
      @section = section
      @for = []
      @original_acks = []
      @msh15_acks = []
      @msh16_acks = []
      V2AD.v2.ack_chors << self
      V2AD.register_to_section(section, self)
    end
  end
  
end
