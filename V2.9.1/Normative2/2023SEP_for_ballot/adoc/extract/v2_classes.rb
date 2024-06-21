module V2AD
  # Abstract
  class V2Obj
    attr_accessor :section, :sequel
  end
end
Dir.glob(File.join(__dir__, 'v2', '**', '*.rb'), &method(:load))
