
Integer.class_eval do

  ##
  # Converts an integer into a hex string with the specified length.
  def to_hex(length = 8)
    to_s(16).rjust(length, '0')
  end

end
